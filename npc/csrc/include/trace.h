#ifndef __TRACE_H
#define __TRACE_H

#include <stdio.h>
#include <stdint.h>
#include <elf.h>

#include "sim_main.h"
#include "debug.h"
#include "reg.h"

#define PRINTF_SPACE(num) for(int __i = 0; __i < num; __i++) printf(" ");
#define MAX_FUN_CALL_TRACE 100

void assert_fail_msg(void);
void ftrace_init(void);
void ftrace(uint32_t pc);

#endif