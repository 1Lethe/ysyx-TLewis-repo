#ifndef __TRACE_H
#define __TRACE_H

#include <elf.h>

#include "reg.h"

#define PRINTF_SPACE(num) for(int __i = 0; __i < num; __i++) printf(" ");
#define MAX_SYM 10000
#define MAX_FUN_CALL_TRACE 1000
#define IRING_BUF_SIZE 16

#define FMT_WORD MUXDEF(CONFIG_ISA64, "0x%016" PRIx64, "0x%08" PRIx32)

void assert_fail_msg(void);
void iring_display(void);
void iring_init(void);
void iring(uint32_t pc, uint32_t inst);
void iring_free(void);
void ftrace_init(void);
void ftrace(uint32_t pc);

#endif