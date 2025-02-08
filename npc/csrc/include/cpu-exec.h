#ifndef __CPU_EXEC
#define __CPU_EXEC

#include "Vysyx_24120013_top.h"
#include "verilated.h"

#include <stdint.h>

#include "sim_main.h"
#include "sim.h"
#include "memory.h"
#include "trace.h"

extern SIM_MODULE* SIM_MODULE_NAME;

void single_cycle(SIM_MODULE* top);
void cycle(SIM_MODULE* top, uint64_t n);
void reset(SIM_MODULE* top, int n);

#endif