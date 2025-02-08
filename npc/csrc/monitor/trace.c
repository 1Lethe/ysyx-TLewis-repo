#include "trace.h"

Elf32_Sym elf_sym[MAX_FUN_CALL_TRACE];
uint32_t elf_sym_num = 0;

uint32_t funcall_name_stack[MAX_FUN_CALL_TRACE] = {0};
int funcall_time = 0;

extern char* elf_file;
extern Elf32_Shdr shdr_strtab;
extern Elf32_Shdr shdr_symtab;

void assert_fail_msg(void){
    printf("PC = 0x%x\n", SIM_MODULE_NAME->pc);
    reg_display(SIM_MODULE_NAME);
    return ;
}

void ftrace_init(void){
  FILE *fp = fopen(elf_file, "r");
  Assert(fp != NULL, "Failed to read elf_file.\nMaybe you use build-in image.In that case, please turn off ftrace.");

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

  fclose(fp);
}

static char *read_sym_str(int off_from_symtable){
  char str_buf;
  static char sym_str[50];
  char *str_ptr = sym_str;

  FILE *fp = fopen(elf_file, "r");
  Assert(fp != NULL, "Failed to read elf_file");

  Assert(fseek(fp, shdr_strtab.sh_offset + elf_sym[off_from_symtable].st_name, SEEK_SET) != -1, \
        "Failed to read '%s' strtab", elf_file);
  memset(sym_str, '\0', 50);
  while((str_buf = fgetc(fp)) != EOF){
    *str_ptr++ = str_buf;
    if(str_buf == '\0') break;
  }

  fclose(fp);

  return sym_str;
}

void ftrace(uint32_t pc){
  static Elf32_Word sym_name = 0;
  static Elf32_Word sym_name_prev = 0;
  static int sym_off = 0;
  static int sym_off_prev = 0;

  for(int i = 0; i < elf_sym_num; i++){
    printf("0x%x 0x%x 0x%x %s\n ",pc, elf_sym[i].st_value,  elf_sym[i].st_value + elf_sym[i].st_size, read_sym_str(i));
    if(ELF32_ST_TYPE(elf_sym[i].st_info) == STT_FUNC && \
      pc >= elf_sym[i].st_value && pc < elf_sym[i].st_value + elf_sym[i].st_size){
      /* Find the function that is executing */
      sym_name_prev = sym_name;
      sym_name = elf_sym[i].st_name;
      sym_off_prev = sym_off;
      sym_off = i;

      /* call function or return from function */
      if(sym_name != sym_name_prev){
        printf("0x%x: ", pc);

        /* NOTE: tail-call oper need to test */
        /* maintain a stack which contain the value of fun in symbol table */
        if(funcall_time == 0){
          /* call _start */
          printf("call");
          funcall_name_stack[funcall_time] = sym_name;
          funcall_time++;
          printf("[%s@0x%x],%d\n", read_sym_str(sym_off), elf_sym[i].st_value, funcall_time);
        }else if(funcall_time == 1){
          /* call _trm_init */
          PRINTF_SPACE(funcall_time);
          funcall_name_stack[funcall_time] = sym_name;
          funcall_time++;
          printf("call[%s@0x%x],%d\n", read_sym_str(sym_off), elf_sym[i].st_value,funcall_time);
        }else{
          if(funcall_time > MAX_FUN_CALL_TRACE){
            panic("fun call time > MAX");
          }else if(funcall_time < 0){
            panic("fun call time < 0");
          }

          int search_time = 0;
          /* The top of stack is the function called previously */
          if(funcall_name_stack[funcall_time - 1] == sym_name_prev){
            for(int j = funcall_time - 1; j > 0; j--){
              search_time++;
              if(funcall_name_stack[j] == sym_name){
                /* If find the sym_name in stack, must be ret */
                /* To implement tail-call oper */
                funcall_time = funcall_time - search_time + 1;
                PRINTF_SPACE(funcall_time + 1);
                printf("ret[%s],%d\n",read_sym_str(sym_off_prev), funcall_time);
                return ;
              }
            }

            /* If not find, must be call */
            funcall_name_stack[funcall_time] = sym_name;
            funcall_time++;
            PRINTF_SPACE(funcall_time);
            printf("call[%s@0x%x],%d\n", read_sym_str(sym_off), elf_sym[i].st_value, funcall_time);
            return ;
          }
        }
      }
      /* find the function then break */
      return ;
    }
    /* not find FUNC type in symbol tab. Must be wrong. */
    if(i == elf_sym_num - 1) panic("Not find function type in symbol tab.");
  }
}