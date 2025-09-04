#ifndef __CPU_EXEC
#define __CPU_EXEC

#include "sim_main.h"
#include "sim.h"
#include "memory.h"
#include "trace.h"

void single_cycle(SIM_MODULE* top);
void cycle(SIM_MODULE* top, uint64_t n);
uint64_t get_cycle_time(void);
void reset(SIM_MODULE* top, int n);

#endif