#include <am.h>
#include <klib-macros.h>
#include <klib.h>
#include <ysyxSoC.h>

extern char _heap_start;
extern char _heap_end;
int main(const char *args);

Area heap = RANGE(&_heap_start, &_heap_end);
static const char mainargs[MAINARGS_MAX_LEN] = MAINARGS_PLACEHOLDER; // defined in CFLAGS

void putch(char ch) {
  outb(UART16550_RB_ADDR, ch);
}

void halt(int code) {
  cpu_trap(code);

  while(1); // should not reach here.
}

void _trm_init() {
  //heap_ptr_reset();
  int ret = main(mainargs);
  halt(ret);
}
