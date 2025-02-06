#ifndef __CPU_EXEC
#define __CPU_EXEC

#include "Vysyx_24120013_top.h"
#include "verilated.h"

#include "sim_main.h"
#include "memory.h"

void single_cycle(SIM_MODULE* top);
void reset(SIM_MODULE* top, int n);

#endif