#include <common.h>
#include <fs.h>
#include "syscall.h"
#include "device.h"

#ifdef CONFIG_STRACE

typedef enum {
  STRACE_NONE = 0,
  STRACE_FILE_PATHNAME
} attach_textconfig;
typedef struct {
  char *name;
  attach_textconfig attach_textconfig_0;
}strace_context;

strace_context strace_ctx[20] = {
  [SYS_exit]  = {"SYS_exit"},   // num = 0
  [SYS_yield] = {"SYS_yield"},  // num = 1
  [SYS_open]  = {"SYS_open",  STRACE_FILE_PATHNAME},   // num = 2
  [SYS_read]  = {"SYS_read",  STRACE_FILE_PATHNAME},   // num = 3
  [SYS_write] = {"SYS_write", STRACE_FILE_PATHNAME},  // num = 4
  [SYS_close] = {"SYS_close", STRACE_FILE_PATHNAME},  // num = 7
  [SYS_lseek] = {"SYS_lseek", STRACE_FILE_PATHNAME},  // num = 8
  [SYS_brk]   = {"SYS_brk"},     // num = 9
  [SYS_gettimeofday] = {"SYS_gettimeofday"}   // num = 19
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
static void strace(int syscall_num, int arg1, int arg2, int arg3){
  char attach_text[100];

  switch(strace_ctx[syscall_num].attach_textconfig_0){
    case STRACE_NONE : memset(attach_text, '\0', sizeof(attach_text)); break;
    case STRACE_FILE_PATHNAME : 
      if(syscall_num == SYS_open) strncpy(attach_text, (char *)arg1, sizeof(attach_text) - 1);
      else strncpy(attach_text, find_fd2name(arg1), sizeof(attach_text) - 1);
      break;
  }

  printf("syscall %d : %s %s\n", syscall_num, strace_ctx[syscall_num].name, attach_text);
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
  strace(a[0], a[1], a[2], a[3]);
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
