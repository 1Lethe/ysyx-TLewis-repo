#ifndef __TRACE_H
#define __TRACE_H

#include <cpu/decode.h>
#include <common.h>
#include <elf.h>
#include <stdio.h>

/* Size of inst ring buffer */
#define IRING_BUF_SIZE 16

#define MAX_FUN_CALL_TRACE 1000

void iring_display(void);
void iring_init(void);
void iring(Decode *s);
void iring_free(void);
void ftrace(Decode *s);

#endif
