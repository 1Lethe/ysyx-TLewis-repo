#include <common.h>
#include <fs.h>
#include "syscall.h"
#include "device.h"

#ifdef CONFIG_STRACE
char strace_text[20][20] = {
  "SYS_exit",   // num = 0
  "SYS_yield",  // num = 1
  "SYS_open",   // num = 2
  "SYS_read",   // num = 3
  "SYS_write",  // num = 4
  "SYS_close",  // num = 7
  "SYS_lseek",  // num = 8
  "SYS_brk",     // num = 9
  "SYS_gettimeofday"   // num = 19
};
#endif

static void f_SYS_halt(int code){
  halt(code);
}

static void f_SYS_yield(void){
  yield();
}

static int f_SYS_open(const char *pathname, int flags, int mode) {
  int ret = fs_open(pathname, flags, mode);
  return ret;
}

static int f_SYS_read(int fd, void *buf, size_t len) {
  int ret = fs_read(fd, buf, len);
  return ret;
}

static long f_SYS_write(int fd, void *buf, int count){
  if(fd_is_valid(fd)){
    int ret = fs_write(fd, buf, count);
    return ret;
  }

  return -1;
}

static int f_SYS_close(int fd) {
  int ret = fs_close(fd);
  return ret;
}

static int f_SYS_lseek(int fd, size_t offset, int whence) {
  int ret = fs_lseek(fd, offset, whence);
  return ret;
}

static int f_SYS_brk(intptr_t addr){
  // TODO: fix f_SYS_brk in PA4
  return 0;
}

static size_t f_SYS_gettimeofday(struct timeval *tv, struct timezone *tz) {
  int ret = timer_gettimeofday(tv, tz);
  return ret;
}

#ifdef CONFIG_STRACE
static void strace(int syscall_num, int arg1){
  int strace_text_index = -1;
  bool display_file_path = false;
  bool display_file_fd = false;

  switch(syscall_num){
    case SYS_exit   : strace_text_index = 0; break;
    case SYS_yield  : strace_text_index = 1; break;
    case SYS_open   : strace_text_index = 2; display_file_path = true ;break;
    case SYS_read   : strace_text_index = 3; display_file_fd = true; break;
    case SYS_write  : strace_text_index = 4; display_file_fd = true; break;
    case SYS_close  : strace_text_index = 5; display_file_fd = true; break;
    case SYS_lseek  : strace_text_index = 6; display_file_fd = true; break;
    case SYS_brk    : strace_text_index = 7; break;
    case SYS_gettimeofday : strace_text_index = 8; break;
    default : return; // syscall not exist
  }

  if(display_file_path == true) printf("%s - ", arg1);
  if(display_file_fd == true) printf("%s - ", find_fd2name(arg1));
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
  strace(a[0], a[1]);
#endif

  switch (a[0]) {
    case SYS_exit   : f_SYS_halt(a[1]); break;
    case SYS_yield  : f_SYS_yield(); break;
    case SYS_open   : *ret_1 = f_SYS_open((void *)a[1], a[2], a[3]); break;
    case SYS_read   : *ret_1 = f_SYS_read(a[1], (void *)a[2], a[3]); break;
    case SYS_write  : *ret_1 = f_SYS_write(a[1], (void *)a[2], a[3]); break;
    case SYS_close  : *ret_1 = f_SYS_close(a[1]); break;
    case SYS_lseek  : *ret_1 = f_SYS_lseek(a[1], a[2], a[3]); break;
    case SYS_brk    : *ret_1 = f_SYS_brk(a[1]); break;
    case SYS_gettimeofday : *ret_1 = f_SYS_gettimeofday((void *)a[1], (void *)a[2]); break;
    default: panic("Unhandled syscall ID = %d", a[0]);
  }
}
