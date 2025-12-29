#ifndef __CPU_EXEC
#define __CPU_EXEC

#include "sim_main.h"
#include "sim.h"
#include "memory.h"
#include "trace.h"
#include "common.h"


#define RISCV_GPR_TYPE uint32_t
#define RISCV_GPR_NUM  MUXDEF(CONFIG_RVE, 16, 32)

typedef struct {
    word_t gpr[RISCV_GPR_NUM];
    word_t pc;
    word_t mstatus;
    word_t mtvec;
    word_t mepc;
    word_t mcause;
} CPU_state;

enum {
    CSR_MSTATUS, CSR_MTVEC, CSR_MEPC, CSR_MCAUSE
};

extern CPU_state cpu;

void single_cycle(SIM_MODULE* top);
void cycle(SIM_MODULE* top, uint64_t n);
uint64_t get_cycle_time(void);
void reset(SIM_MODULE* top, int n);

#endif