#include <common.h>
#include "syscall.h"

#ifdef CONFIG_STRACE
char strace_text[32][32] = {
  "SYS_halt",   // num = 0
  "SYS_yield",  // num = 1
  "",
  "",
  "SYS_write",  // num = 4
  "SYS_brk"
};
#endif

static void SYS_halt(int code){
  halt(code);
}

static void SYS_yield(void){
  yield();
}

static long SYS_write(int fd, void *buf, int count){
  assert(fd == 0 || fd == 1 || fd == 2);
  // fd is stdout(== 1) or stderr(== 2)
  if(fd == 1 || fd == 2){
    int charput_num = 0;
    char *char_buf = (char *)(intptr_t)buf;

    for(int i = 0; i < count; i++){
      putch(*char_buf++);
      charput_num++;
    }

    return charput_num;
  }
  return -1;
}

static int SYS_brk(intptr_t addr){
  // TODO: fix SYS_brk in PA4
  return 0;
}

#ifdef CONFIG_STRACE
static void strace(int syscall_num){
  int strace_text_index = -1;

  switch(syscall_num){
    case 0x0 : strace_text_index = 0; break;
    case 0x1 : strace_text_index = 1; break;
    case 0x4 : strace_text_index = 4; break;
    case 0x9 : strace_text_index = 5; break;
    default : return; // syscall not exist
  }

  printf("syscall %d : %s\n", syscall_num, strace_text[strace_text_index]);
}
#endif

void do_syscall(Context *c) {
  uintptr_t a[4];
  uintptr_t *ret_1 = (uintptr_t *)&c->GPRx;

  a[0] = c->GPR1;
  a[1] = c->GPR2;
  a[2] = c->GPR3;
  a[3] = c->GPR4;

#ifdef CONFIG_STRACE
  strace(a[0]);
#endif

  switch (a[0]) {
    case 0x0 : SYS_halt(a[1]); break;
    case 0x1 : SYS_yield(); break;
    case 0x4 : *ret_1 = SYS_write(a[1], (void *)a[2], a[3]); break;
    case 0x9 : *ret_1 = SYS_brk(a[1]); break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
}
