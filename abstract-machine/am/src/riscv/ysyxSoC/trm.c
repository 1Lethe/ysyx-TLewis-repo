#include <am.h>
#include <klib-macros.h>
#include <klib.h>
#include <ysyxSoC.h>

extern char _heap_start;
extern char _heap_end;

int main(const char *args);

Area heap = RANGE(&_heap_start, &_heap_end);
static const char mainargs[MAINARGS_MAX_LEN] = MAINARGS_PLACEHOLDER; // defined in CFLAGS

static void UART16550_init(void) {
/*
  Set the Line Control Register to the desired line control parameters. Set bit 7 to ‘1’ 
  to allow access to the Divisor Latches.
*/
  outb(UART16550_LCR_ADDR, 0x83);
/*
  Set the Divisor Latches, MSB first, LSB next. 
  TODO: calc divisor in NVBoard
*/
  outb(UART16550_DL_MSB_ADDR, 0x00);
  outb(UART16550_DL_LSB_ADDR, 0x01);
/*
  Set bit 7 of LCR to ‘0’ to disable access to Divisor Latches. At this time the 
  transmission engine starts working and data can be sent and received
*/
  outb(UART16550_LCR_ADDR, 0x03);
/*
  Set the FIFO trigger level. Generally, higher trigger level values produce less 
  interrupt to the system, so setting it to 14 bytes is recommended if the system 
  responds fast enough.
*/
  outb(UART16550_FCR_ADDR, 0xC0);
}

// print ysyx_24120013
static void YSYX_welcome(void) {
  uint32_t mvendorid_val;
  uint32_t marchid_val;
  asm volatile("csrrs %0, mvendorid, zero" : "=r"(mvendorid_val));
  asm volatile("csrrs %0, marchid,   zero" : "=r"(marchid_val));

  putstr("Hello YSYX!");
  putch((mvendorid_val >> 24) & 0xFF); // 提取 0x79 -> 'y'
  putch((mvendorid_val >> 16) & 0xFF); // 提取 0x73 -> 's'
  putch((mvendorid_val >> 8)  & 0xFF); // 提取 0x79 -> 'y'
  putch((mvendorid_val)       & 0xFF); // 提取 0x78 -> 'x'

  putch('_');

  if (marchid_val == 0) {
      putch('0');
  } else {
    char buf[12]; 
    int i = 0;
    uint32_t temp = marchid_val;

    // 逐位提取 (从低位到高位)
    while (temp > 0) {
      buf[i++] = (temp % 10) + '0'; // 取余并转 ASCII
      temp /= 10;                   // 移位
    }
    while (i > 0) {
      putch(buf[--i]);
    }
  }

  putch('\n');
}

void putch(char ch) {
  // 轮询等待串口FIFO为空
  while(((uint8_t)inb(UART16550_LSR_ADDR) & 0x40) != 0x40);
  outb(UART16550_RB_ADDR, ch);
}

void halt(int code) {
  cpu_trap(code);

  while(1); // should not reach here.
}

void _trm_init() {
  heap_ptr_reset();
  UART16550_init();

  YSYX_welcome();

  int ret = main(mainargs);
  halt(ret);
}
