#include <cpu/trace.h>

char *iringbuf[IRING_BUF_SIZE];
int iring_index = 0;

Elf32_Sym elf_sym[MAX_FUN_CALL_TRACE];
uint32_t elf_sym_num = 0;

uint32_t funcall_value_stack[MAX_FUN_CALL_TRACE] = {0};
int funcall_time = 0;

extern char *elf_file;
extern Elf32_Shdr shdr_strtab;
extern Elf32_Shdr shdr_symtab;

void iring_display(void){
  for(int i = 0; i < IRING_BUF_SIZE; i++){
    if(iringbuf[i] == NULL) continue;
    printf("%s", iringbuf[i]);
    if(i != iring_index - 1){
      printf("\n");
    }else{
      printf("<----- Program crash\n");
    }
  }
}

/* Init iringbuf */
void iring_init(void){
  for(int i = 0; i < IRING_BUF_SIZE; i++){
    iringbuf[i] = NULL;
  }
}

/* iringbuf implementation */
void iring(Decode *s){
  static bool iring_cycle_flag = false;

  if(iring_index == IRING_BUF_SIZE){
    iring_cycle_flag = true;
    iring_index = 0;
  }

  /* If cycle at least once, free */
  if(iring_cycle_flag){
    Assert(iringbuf[iring_index] != NULL, "iringbuf[%d] == NULL", iring_index);
    free(iringbuf[iring_index]);
  }

  char *instbuf = (char *)malloc(128*sizeof(char));
  Assert(instbuf != NULL, "failed to malloc instbuf");
  memset(instbuf, '\0', 128*sizeof(char));
  memcpy(instbuf, s->logbuf, 128*sizeof(char));
  iringbuf[iring_index++] = instbuf;
}

/* Free iringbuf */
void iring_free(void){
  for(int i = 0; i < IRING_BUF_SIZE - 1; i++){
    if(iringbuf[i] == NULL){
      continue;
    }
    free(iringbuf[i]);
  }
}

void ftrace_init(void){

  FILE *fp = fopen(elf_file, "r");
  Assert(fp != NULL, "Failed to read elf_file");

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

char *read_sym_str(Elf32_Word off){
  char str_buf;
  static char sym_str[50];
  char *str_ptr = sym_str;

  FILE *fp = fopen(elf_file, "r");
  Assert(fp != NULL, "Failed to read elf_file");

  Assert(fseek(fp, shdr_strtab.sh_offset + elf_sym[off].st_name, SEEK_SET) != -1, \
        "Failed to read '%s' strtab", elf_file);
  memset(sym_str, '\0', 50);
  while((str_buf = fgetc(fp)) != EOF){
    *str_ptr++ = str_buf;
    if(str_buf == '\0') break;
  }

  fclose(fp);

  return sym_str;
}

void ftrace(Decode *s){
  static Elf32_Word sym_value = 0;
  static Elf32_Word sym_value_prev = 0;
  static int sym_off = 0;
  static int sym_off_prev = 0;

  vaddr_t pc = s->pc;

  for(int i = 0; i < elf_sym_num; i++){
    /* not find FUNC type in symbol tab. Must be wrong. */
    if(i == elf_sym_num - 1) panic("Not find function type in symbol tab.");

    if(ELF32_ST_TYPE(elf_sym[i].st_info) == STT_FUNC && \
      pc >= elf_sym[i].st_value && pc < elf_sym[i].st_value + elf_sym[i].st_size){
      /* Find the function that is executing */
      sym_value_prev = sym_value;
      sym_value = elf_sym[i].st_value;
      sym_off_prev = sym_off;
      sym_off = i;

      /* call function or return from function */
      if(sym_value != sym_value_prev){
        printf("0x%x: ", pc);

        /* maintain a stack which contain the value of fun in symbol table */
        if(funcall_time == 0){
          /* call _start */
          printf("call");
          funcall_value_stack[funcall_time] = sym_value;
          funcall_time++;
          printf("[%s@0x%x]\n", read_sym_str(sym_off), elf_sym[i].st_value);
        }else if(funcall_time == 1){
          /* call _trm_init */
          printf(" ");
          printf("call");
          funcall_value_stack[funcall_time] = sym_value;
          funcall_time++;
          printf("[%s@0x%x]\n", read_sym_str(sym_off), elf_sym[i].st_value);
        }else{
          if(funcall_value_stack[funcall_time - 1] == sym_value_prev && \
              funcall_value_stack[funcall_time - 2] == sym_value){
            funcall_value_stack[funcall_time - 1] = 0;
            for(int i = 0;i < funcall_time - 1; i++) printf(" ");
            printf("ret");
            funcall_time--;
            printf("[%s]\n", read_sym_str(sym_off_prev));
          }else{
            funcall_value_stack[funcall_time] = sym_value;
            funcall_time++;
            for(int i = 0;i < funcall_time - 1; i++) printf(" ");
            printf("call");
            printf("[%s@0x%x]\n", read_sym_str(sym_off), elf_sym[i].st_value);
          }
        }
      }
    }
    /* find the function then break */
    break;
  }
}

