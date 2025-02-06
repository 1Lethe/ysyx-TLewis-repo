#include "../../include/sdb.h"

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
  cycle(SIM_MODULE_NAME, 1);
  return 0;
}

static int cmd_q(char *args) {
  return -1;
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
  //{"info", "Display the value of regs or watch.usage: info <r/w/b>", cmd_info},
  //{"x", "Scan memory.usage: x <scan_num> <mem_start_place>", cmd_x},
}

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