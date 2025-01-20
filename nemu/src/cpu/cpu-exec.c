/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <cpu/cpu.h>
#include <cpu/decode.h>
#include <cpu/difftest.h>
#include <memory/paddr.h>
#include <locale.h>
#include <elf.h>

bool trace_wp();
bool trace_bp(Decode *s);

/* Size of inst ring buffer */
#define IRING_BUF_SIZE 16
#define MAX_FUN_CALL_TRACE 1000

/* The assembly code of instructions executed is only output to the screen
 * when the number of instructions executed is less than this value.
 * This is useful when you use the `si' command.
 * You can modify this value as you want.
 */
#define MAX_INST_TO_PRINT 10

CPU_state cpu = {};
uint64_t g_nr_guest_inst = 0;
static uint64_t g_timer = 0; // unit: us
static bool g_print_step = false;
char *iringbuf[IRING_BUF_SIZE];
int iring_index = 0;

extern char *elf_file;

extern Elf32_Shdr shdr_strtab;
extern Elf32_Shdr shdr_symtab;

uint32_t funcall_stack[MAX_FUN_CALL_TRACE];

void device_update();
static void ftrace(Decode *s);

static void trace_and_difftest(Decode *_this, vaddr_t dnpc) {
#ifdef CONFIG_ITRACE_COND
  if (ITRACE_COND) { log_write("%s\n", _this->logbuf); }
#endif
  if (g_print_step) { IFDEF(CONFIG_ITRACE, puts(_this->logbuf)); }
  IFDEF(CONFIG_DIFFTEST, difftest_step(_this->pc, dnpc));

  /* Trace watchpoint */
  bool is_wp_stop = false;
  bool is_bp_stop = false;
#ifdef CONFIG_WATCHPOINT
  is_wp_stop = trace_wp();
#endif
#ifdef CONFIG_BREAKPOINT
  is_bp_stop = trace_bp(_this);
#endif
  if(is_wp_stop || is_bp_stop) nemu_state.state = NEMU_STOP;
}

static void exec_once(Decode *s, vaddr_t pc) {
  s->pc = pc;
  s->snpc = pc;// update s->pc and s->snpc.
  isa_exec_once(s); // fetch inst to isa->inst and execute inst s->pc and update s-> dnpc.
  cpu.pc = s->dnpc; // update cpu.pc
#ifdef CONFIG_ITRACE
  char *p = s->logbuf;
  p += snprintf(p, sizeof(s->logbuf), FMT_WORD ":", s->pc);
  int ilen = s->snpc - s->pc;
  int i;
  uint8_t *inst = (uint8_t *)&s->isa.inst;
#ifdef CONFIG_ISA_x86
  for (i = 0; i < ilen; i ++) {
#else
  for (i = ilen - 1; i >= 0; i --) {
#endif
    p += snprintf(p, 4, " %02x", inst[i]);
  }
  int ilen_max = MUXDEF(CONFIG_ISA_x86, 8, 4);
  int space_len = ilen_max - ilen;
  if (space_len < 0) space_len = 0;
  space_len = space_len * 3 + 1;
  memset(p, ' ', space_len);
  p += space_len;

  void disassemble(char *str, int size, uint64_t pc, uint8_t *code, int nbyte);
  disassemble(p, s->logbuf + sizeof(s->logbuf) - p,
      MUXDEF(CONFIG_ISA_x86, s->snpc, s->pc), (uint8_t *)&s->isa.inst, ilen);

  /* iringbuf implementation */
  static bool iring_cycle_flag = false;
  static bool iring_buf_init_flag = false;
  if(!iring_buf_init_flag){
    iring_buf_init_flag = true;
    for(int i = 0; i < IRING_BUF_SIZE; i++){
      iringbuf[i] = NULL;
    }
  }
  if(iring_index == IRING_BUF_SIZE - 1){
    iring_cycle_flag = true;
    iring_index = 0;
  }
  if(iring_cycle_flag){
    Assert(iringbuf[i] == NULL, "iringbuf[i] == NULL");
    free(iringbuf[i]);
  }
  char *instbuf = (char *)malloc(128*sizeof(char));
  Assert(instbuf != NULL, "failed to malloc instbuf");
  memset(instbuf, '\0', 128*sizeof(char));
  memcpy(instbuf, s->logbuf, 128*sizeof(char));
  iringbuf[iring_index++] = instbuf;
#endif

  ftrace(s);

}

static void execute(uint64_t n) {
  Decode s;
  for (;n > 0; n --) {
    exec_once(&s, cpu.pc);
    g_nr_guest_inst ++;
    trace_and_difftest(&s, cpu.pc);
    if (nemu_state.state != NEMU_RUNNING) break;// Run program till quit or end
    IFDEF(CONFIG_DEVICE, device_update());
  }
}

static void statistic() {
  IFNDEF(CONFIG_TARGET_AM, setlocale(LC_NUMERIC, ""));
#define NUMBERIC_FMT MUXDEF(CONFIG_TARGET_AM, "%", "%'") PRIu64
  Log("host time spent = " NUMBERIC_FMT " us", g_timer);
  Log("total guest instructions = " NUMBERIC_FMT, g_nr_guest_inst);
  if (g_timer > 0) Log("simulation frequency = " NUMBERIC_FMT " inst/s", g_nr_guest_inst * 1000000 / g_timer);
  else Log("Finish running in less than 1 us and can not calculate the simulation frequency");
}

static void iringbuf_display(void){
  for(int i = 0; i < IRING_BUF_SIZE - 1; i++){
    if(iringbuf[i] == NULL) break;
    printf("%s", iringbuf[i]);
    if(i != iring_index){
      printf("\n");
    }else{
      printf("<----- Program crash.\n");
    }
  }
}

static void ftrace(Decode *s){
  static bool symtab_init_flag = false;
  static Elf32_Sym elf_sym[MAX_FUN_CALL_TRACE];
  static uint32_t elf_sym_num = 0;

  FILE *fp = fopen(elf_file, "r");
  Assert(fp != NULL, "Failed to read elf_file");

  if(!symtab_init_flag){
    symtab_init_flag = true;

    /* Init ELF symbol table */
    Assert(fseek(fp, shdr_symtab.sh_offset, SEEK_SET) != -1, \
      "Failed to read '%s' symtab", elf_file);
    elf_sym_num = shdr_symtab.sh_size / shdr_symtab.sh_entsize;
    for(int i = 0; i < elf_sym_num; i++){
      Assert(fseek(fp, shdr_symtab.sh_offset + i * shdr_symtab.sh_entsize, SEEK_SET) != -1, \
        "Failed to read '%s' symtab[%d]", elf_file, i);
      Assert(fread(&elf_sym[i], 1, shdr_symtab.sh_entsize, fp) == shdr_symtab.sh_entsize, \
        "Failed to read '%s' symtab[%d]", elf_file, i);

      }
    }

  vaddr_t pc = s->pc;
  static Elf32_Word sym_value_prev = 0;
  static Elf32_Word sym_value = 0;
  for(int i = 0; i < elf_sym_num; i++){
    if(ELF32_ST_TYPE(elf_sym[i].st_info) == STT_FUNC && \
      pc >= elf_sym[i].st_value && pc < elf_sym[i].st_value + elf_sym[i].st_size){
      /* Find the function that is executing */
      Assert(fseek(fp, shdr_strtab.sh_offset + elf_sym[i].st_name, SEEK_SET) != -1, \
        "Failed to read '%s' strtab", elf_file);

      sym_value_prev = sym_value;
      sym_value = elf_sym[i].st_value;
      if(sym_value != sym_value_prev){
        char str_buf;
        char str[20];
        char *str_ptr = str;
        memset(str, '\0', 20);
        while((str_buf = fgetc(fp)) != EOF){
          *str_ptr++ = str_buf;
          if(str_buf == '\0') break;
        }
        printf("value : %x  ", elf_sym[i].st_value);
        printf("name : %s\n", str);
      }

      break;
    }
    /* not find FUNC type in symbol tab. Must be wrong. */
    panic("Not find function type in symbol tab.");
  }

  fclose(fp);
}

static void iringbuf_free(void){
  /* Free iringbuf */
  for(int i = 0; i < IRING_BUF_SIZE - 1; i++){
    if(iringbuf[i] == NULL){
      continue;
    }
    free(iringbuf[i]);
  }
}

void assert_fail_msg() {
  isa_reg_display();
#ifdef CONFIG_ITRACE
  iringbuf_display();
  iringbuf_free();
#endif
  statistic();
}

/* Simulate how the CPU works. */
void cpu_exec(uint64_t n) {
  g_print_step = (n < MAX_INST_TO_PRINT);
  switch (nemu_state.state) {
    case NEMU_END: case NEMU_ABORT: case NEMU_QUIT:
      printf("Program execution has ended. To restart the program, exit NEMU and run again.\n");
      return;
    default: nemu_state.state = NEMU_RUNNING;
  }

  uint64_t timer_start = get_time();

  execute(n);// execute command

  uint64_t timer_end = get_time();
  g_timer += timer_end - timer_start;

  switch (nemu_state.state) {
    case NEMU_RUNNING: nemu_state.state = NEMU_STOP; break;

    case NEMU_END: case NEMU_ABORT:
      Log("nemu: %s at pc = " FMT_WORD,
          (nemu_state.state == NEMU_ABORT ? ANSI_FMT("ABORT", ANSI_FG_RED) :
           (nemu_state.halt_ret == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) :
            ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED))),
          nemu_state.halt_pc);
      // fall through
    case NEMU_QUIT: iringbuf_free();statistic();
  }
}
