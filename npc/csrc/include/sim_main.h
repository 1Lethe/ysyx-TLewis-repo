#ifndef __SIM_MAIN_H
#define __SIM_MAIN_H

#include "Vysyx_24120013_top.h"
#include "verilated.h"

//If you want to use testbench just keep this #define otherwise delete it
//#define USE_TESTBENCH

#define SIM_MODULE Vysyx_24120013_top
#define SIM_MODULE_NAME top
//Usually use DPI-C to end sim, we need to put ebreak in pmem .
#define SIM_TIME_MAX 500000

extern SIM_MODULE* SIM_MODULE_NAME;

void sim_init(int argc, char** argv[]);
void dump_wave(SIM_MODULE* top);

#endif