#ifndef __SIM_MAIN_H
#define __SIM_MAIN_H

//If you want to use testbench just keep this #define otherwise delete it
//#define USE_TESTBENCH

#define SIM_MODULE Vysyx_24120013_top
#define SIM_MODULE_NAME top
//Usually use DPI-C to end sim, we need to put ebreak in pmem .
#define SIM_TIME_MAX 500

void halt(void);
void sim_init(int argc, char** argv[]);
void dump_wave(SIM_MODULE* top);
#ifndef USE_TESTBENCH
void single_cycle(SIM_MODULE* top);
void reset(SIM_MODULE* top, int n);
#endif

#endif