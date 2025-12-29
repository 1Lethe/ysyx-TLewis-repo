
#ifndef __SIM_H
#define __SIM_H

#include "verilated_fst_c.h"
#include "VysyxSoCFull__Dpi.h"

#include "sim_main.h"

void sim_init(int argc, char **argv);
void dump_wave(SIM_MODULE* top);
bool is_sim_continue(void);
void update_simenv_cpu_state(void);
void tfp_close(void);

#endif