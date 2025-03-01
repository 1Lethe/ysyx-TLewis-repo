#ifndef NPC_H__
#define NPC_H__

#include <klib-macros.h>

#include ISA_H

#define npc_trap(code) asm volatile("mv a0, %0; ebreak" : :"r"(code))

#define SERIAL_PORT 0xa00003f8
#define RTC_ADDR    0xa0000048

#endif