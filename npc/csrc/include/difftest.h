#ifndef __DIFFTEST_H
#define __DIFFTEST_H

#include <dlfcn.h>

#include "memory.h"
#include "utils.h"
#include "cpu-exec.h"
#include "common.h"

extern CPU_state cpu;

enum { DIFFTEST_TO_DUT, DIFFTEST_TO_REF };

#define DIFFTEST_REG_SIZE (sizeof(RISCV_GPR_TYPE) * (RISCV_GPR_NUM + 1)) // GPRs + pc

void init_difftest(char *ref_so_file, long img_size, int port);
void difftest_skip_ref();
bool difftest_step(uint32_t pc, uint32_t npc);
#endif