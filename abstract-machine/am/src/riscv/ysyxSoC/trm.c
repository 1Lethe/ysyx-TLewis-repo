#include <am.h>
#include <klib-macros.h>
#include <klib.h>
#include <ysyxSoC.h>

extern char _heap_start;
extern char _heap_end;

extern char _data_vma_start;
extern char _data_vma_end;
extern char _data_lma_start;

extern char _bss_vma_start;
extern char _bss_vma_end;

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
  heap_ptr_reset();

  volatile char *src = &_data_lma_start;
  volatile char *dst = &_data_vma_start;
  while(dst < &_data_vma_end) {
    *dst++ = *src++;
  }

  dst = &_bss_vma_start;
  while(dst < &_bss_vma_end) {
    *dst++ = 0;
  }

  int ret = main(mainargs);
  halt(ret);
}
