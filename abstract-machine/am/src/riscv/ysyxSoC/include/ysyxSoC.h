#ifndef __YSYXSOC_H
#define __YSYXSOC_H

#include <klib-macros.h>

#include ISA_H

#define UART16550_PORT           0x10000000
#define UART16550_RB_ADDR        (UART16550_PORT + 0x0) // Receiver Buffer
#define UART16550_THR_ADDR       (UART16550_PORT + 0x0) // Transmitter Holding Register (THR)
#define UART16550_FCR_ADDR       (UART16550_PORT + 0x2) // FIFO Control Register (FCR)
#define UART16550_LCR_ADDR       (UART16550_PORT + 0x3) // Line Control Register (LCR) 
#define UART16550_LSR_ADDR       (UART16550_PORT + 0x5) // Line Status Register (LSR)
#define UART16550_DL_LSB_ADDR    (UART16550_PORT + 0x0) // Divisor Latches LSB
#define UART16550_DL_MSB_ADDR    (UART16550_PORT + 0x1) // Divisor Latches MSB

#define SPI_MASTER_PORT          0x30000000
#define SPI_MASTER_Rx0           (SPI_MASTER_PORT + 0x0)
#define SPI_MASTER_Rx1           (SPI_MASTER_PORT + 0x4)
#define SPI_MASTER_Tx0           (SPI_MASTER_PORT + 0x0)
#define SPI_MASTER_Tx1           (SPI_MASTER_PORT + 0x4)
#define SPI_MASTER_CSR           (SPI_MASTER_PORT + 0x10)
#define SPI_MASTER_DIVIDER       (SPI_MASTER_PORT + 0x14)
#define SPI_MASTER_SS            (SPI_MASTER_PORT + 0x18)

#define RTC_ADDR          0x02000000

#define cpu_trap(code) asm volatile("mv a0, %0; ebreak" : :"r"(code))

#endif