#ifndef __DIFFTEST_H
#define __DIFFTEST_H

#include <dlfcn.h>

#include "memory.h"
#include "utils.h"
#include "debug.h"

enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };

#define RISCV_GPR_TYPE uint32_t
#define RISCV_GPR_NUM  MUXDEF(CONFIG_RVE, 16, 32)
#define DIFFTEST_REG_SIZE (sizeof(RISCV_GPR_TYPE) * (RISCV_GPR_NUM + 1)) // GPRs + pc

typedef struct {
    word_t gpr[RISCV_GPR_NUM];
    word_t pc;
    word_t mstatus;
    word_t mtvec;
    word_t mepc;
    word_t mcause;
} CPU_state;

void init_difftest(SIM_MODULE* top, char *ref_so_file, long img_size, int port);
void difftest_skip_ref();
bool difftest_step(SIM_MODULE* top, uint32_t pc, uint32_t npc);
#endif