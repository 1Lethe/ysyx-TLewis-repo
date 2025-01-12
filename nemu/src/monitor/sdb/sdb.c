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

#include <isa.h>
#include <cpu/cpu.h>
#include <utils.h>
#include <memory/paddr.h>
#include <readline/readline.h>
#include <readline/history.h>
#include "sdb.h"

extern NEMUState nemu_state;

static int is_batch_mode = false;

void init_regex();
void init_wp_pool();
void init_bp_pool();

/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(nemu) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(-1);
  return 0;
}

static int cmd_q(char *args) {
  nemu_state.state = NEMU_QUIT; // Elegantly exit.
  return -1;
}

static int cmd_si(char *args) {
  int stepNum = 1;

  if(args == NULL){
    cpu_exec(1);
  }else{
    sscanf(args, "%d", &stepNum);
    cpu_exec(stepNum);
  }
  return 0;
}

static int cmd_info(char *args){
  char *arg = strtok(NULL, " ");

  if(arg == NULL){
    printf("Command need args.r: regs,w: watchpoints.b: breakpoints.\n");
  }else{
    if(*arg == 'r'){
      isa_reg_display();
    }else if(*arg == 'w'){
      info_wp();
    }else if(*arg == 'b'){
      info_bp();
    }else{
      printf("Invalid info command input.\n");
    }
  }
  return 0;
}

static int cmd_x(char *args){
  uint8_t *pmem_scan = NULL;
  uint32_t scan_num;
  uint32_t mem_start_place;

  if(args == NULL){
    printf("Command x need args.\n");
    return 0;
  }
  if(sscanf(args, "%d %x", &scan_num, &mem_start_place) == 2){
    if(scan_num <= 0){
      printf("Invalid scan_num input.This arg should > 0.\n");
      return 0;
    }
    if(mem_start_place < PMEM_LEFT || mem_start_place + scan_num > PMEM_RIGHT){
      printf("Invalid input.This arg should be valid.\n");
      printf("physical memory area [" FMT_PADDR ", " FMT_PADDR "]\n", PMEM_LEFT, PMEM_RIGHT);
      return 0;
    }
    
    int base_add = mem_start_place;
    for(int i = 0;i < scan_num;i++){
      int offset = i % 4;
      if(offset == 0){
        if(i != 0){
          printf("\n");
        }
        printf("0x%08x : ", mem_start_place + i);
        base_add += 0x4;
      }
      pmem_scan = guest_to_host(base_add + offset);
      printf("%02x", *pmem_scan);
    }
  }else{
    printf("Invalid x command input.\n");
  }
  return 0;
}

static int cmd_p(char *args){
  word_t val = 0;
  bool success_flag;
  if(args == NULL){
    printf("Command p need args.");
    return 0;
  }
  val = expr(args, &success_flag);
  if(success_flag){
    printf("Expression %s val :\n DEC: %d HEX : 0x%x\n", args, val, val);
  }
  return 0;
}

static int cmd_echo(char *args){
  printf("%s\n", args);
  return 0;
}

// BUG: breakpoint cannot set in ebreak !!! wait PA2 to fix it
static int cmd_w(char *args){
  if(args == NULL){
    printf("command w need args.\n");
    return 0;
  }

  bool success = true;
  create_wp(args, &success);
  if(!success){
    printf("Failed to create watchpoint.\n");
  }else{
    printf("Create watchpoint.\n");
  }
  return 0;
}

static int cmd_dw(char *args){
  int wp_th = 0;

  if(args == NULL){
    printf("command d need args.\n");
    return 0;
  }

  if(sscanf(args, "%d", &wp_th) == 1){
    delete_wp(wp_th);
  }else{
    printf("Invalid d command input.\n");
  }
  return 0;
}

static int cmd_b(char *args){
  int b_place = 0;
  bool success_flag = true;
  
  if(args == NULL){
    printf("command b need args.\n");
    return 0;
  }

  if(sscanf(args, "0x%x", &b_place) == 1){
    create_bp(b_place, &success_flag);
    if(success_flag){
      printf("Create breakpoint at PC = 0x%x.\n", b_place);
    }else{
      printf("Failed to create breakpoint.\n");
    }
  }else{
    printf("Invalid b command input.\n");
  }
  return 0;
}

static int cmd_db(char *args){
  int bp_th = 0;

  if(args == NULL){
    printf("command db need args.\n");
    return 0;
  }

  if(sscanf(args, "%d", &bp_th) == 1){
    delete_bp(bp_th);
  }else{
    printf("Invalid db command input.\n");
  }
  return 0;
}

static int cmd_help(char *args);

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "help", "Display information about all supported commands", cmd_help },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NEMU", cmd_q },

  /* TODO: Add more commands */
  {"si", "Step to the pointed instruction.usage: si [stepNum]" , cmd_si},
  {"info", "Display the value of regs or watch.usage: info <r/w/b>", cmd_info},
  {"x", "Scan memory.usage: x <scan_num> <mem_start_place>", cmd_x},
  {"p", "Solve the expression.usage: p <expression>", cmd_p},
  {"echo", "echo something.usage: echo <str>", cmd_echo},
  {"w", "Add watchpoint.usage: w <expression>", cmd_w},
  {"dw", "Delete watchpoint.usage: d <wp_th>", cmd_dw},
  {"b", "Add breakpoint.usage: b <pc_step>", cmd_b},
  {"db", "Delete breakpoint.usage: db <bp_th>", cmd_db},
};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

void sdb_mainloop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }

#ifdef CONFIG_DEVICE
    extern void sdl_clear_event_queue();
    sdl_clear_event_queue();
#endif

    /* decode input instructions */
    int i;
    for (i = 0; i < NR_CMD; i ++) { 
      if (strcmp(cmd, cmd_table[i].name) == 0) { // Match the instruction table item by item , If match then
        if (cmd_table[i].handler(args) < 0) { return; } // execution instruction till return -1 (cmd_q)
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}


void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();

  /* Initialize the breakpoint pool. */
  init_bp_pool();
}
