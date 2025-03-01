#ifndef __SIM_MAIN_H
#define __SIM_MAIN_H

#include "Vysyx_24120013_top.h"
#include "verilated.h"

#define SIM_MODULE Vysyx_24120013_top
#define SIM_MODULE_NAME top

extern SIM_MODULE* SIM_MODULE_NAME;

void sim_init(int argc, char** argv[]);
void dump_wave(SIM_MODULE* top);

#endif