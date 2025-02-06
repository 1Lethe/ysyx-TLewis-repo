
#ifndef __SIM
#define __SIM

#include "Vysyx_24120013_top.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include "Vysyx_24120013_top__Dpi.h"

#include <stdio.h>

#include "sim_main.h"

void sim_init(int argc, char **argv);
void dump_wave(SIM_MODULE* top);
bool is_sim_continue(void);
void tfp_close(void);

#endif