#ifndef __YSYXSOC_H
#define __YSYXSOC_H

#include <klib-macros.h>

#include ISA_H

#define UART16550_PORT      0x10000000
#define UART16550_RB_ADDR   (UART16550_PORT + 0)

#define RTC_ADDR          0xa0000048

#define cpu_trap(code) asm volatile("mv a0, %0; ebreak" : :"r"(code))

#endif