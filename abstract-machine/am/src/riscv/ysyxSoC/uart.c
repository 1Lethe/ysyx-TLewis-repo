#include <am.h>
#include <ysyxSoC.h>

void __am_uart_rx(AM_UART_RX_T *uart) {
  uint8_t is_recv = inb(UART16550_LSR_ADDR) & 0x01;
  if(is_recv == 0x01) {
    uint8_t dat = inb(UART16550_RB_ADDR);
    uart->data = dat;
  }else {
    uart->data = 0xff;
  }
}