#include "common.h"
#include "sdb.h"

extern SIM_MODULE* SIM_MODULE_NAME;
extern bool is_batch_mode;

static char* rl_gets() {
  static char *line_read = NULL;

  if(line_read){
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(npc) ");

  if(line_read && *line_read){
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cycle(SIM_MODULE_NAME, -1);
  return 0;
}

static int cmd_si(char *args) {
  int step_num = 1;

  if(args == NULL){
    cycle(SIM_MODULE_NAME, 1);
  }else{
    sscanf(args, "%d", &step_num);
    cycle(SIM_MODULE_NAME, step_num);
  }
  return 0;
}

static int cmd_q(char *args) {
  return -1;
}

static int cmd_info(char *args){
  char *arg = strtok(NULL, " ");

  if(arg == NULL){
    printf("Command need args.r: regs\n");
  }else{
    if(*arg == 'r'){
      reg_display();
    }else{
      printf("Invalid info command input.\n");
    }
  }
  return 0;
}

static int cmd_x_mrom(char *args){
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
    if(!(host_in_mrom(mem_start_place) & host_in_mrom(mem_start_place + scan_num))){
      printf("input out of bound.\n");
      return 0;
    }
    
    int base_add = mem_start_place;
    for(int i = 0;i < scan_num;i++){
      int offset = i % 4;
      if(offset == 0){
        if(i == 0){
          printf("0x%08x : ", mem_start_place);
        }else{
          printf("\n");
          printf("0x%08x : ", mem_start_place + i);
          base_add += 0x4;
        }
      }
      pmem_scan = rd_mrom_addr(base_add + 3 - offset + MROM_BASE);
      printf("%02x", *pmem_scan);
    }
    printf("\n");
    
  }else{
    printf("Invalid x command input.\n");
  }
  return 0;
}

#define NR_CMD ARRLEN(cmd_table)

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NPC", cmd_q },

  {"si", "Step to the pointed instruction.usage: si [stepNum]" , cmd_si},
  {"info", "Display the value of regs.usage: info <r>", cmd_info},
  {"x_mrom", "Scan memory.usage: x <scan_num> <mem_start_place>", cmd_x_mrom},
};

void sdb_mainloop() {
  if(is_batch_mode){
    cmd_c(NULL);
    return;
  }

  for(char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    char *cmd = strtok(str, " ");
    if(cmd == NULL){ continue; }

    char *args = cmd + strlen(cmd) + 1;
    if(args >= str_end){
      args = NULL;
    }

    int i;
    for(i = 0; i < NR_CMD; i++){
      if(strcmp(cmd, cmd_table[i].name) == 0){
        if(cmd_table[i].handler(args) < 0) { return ; }
        break;
      }
    }

    if(i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}