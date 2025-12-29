#ifndef __SIM_MAIN_H
#define __SIM_MAIN_H

#include "VysyxSoCFull.h"
#include "verilated.h"

#define SIM_MODULE VysyxSoCFull
#define SIM_MODULE_NAME ysyxSoCfull
#define CPU_MODULE VysyxSoCFull_ysyx_24120013
#define CPU_MODULE_NAME ysyx_24120013

extern SIM_MODULE* SIM_MODULE_NAME;

void sim_init(int argc, char** argv[]);
void dump_wave(SIM_MODULE* top);

#endif