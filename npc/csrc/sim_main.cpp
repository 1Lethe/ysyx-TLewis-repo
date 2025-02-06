//Still need to change this #include and SIM_NAME in makefile to change sim module.
#include "Vysyx_24120013_top.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include "Vysyx_24120013_top__Dpi.h"

#include "include/cpu-exec.h"
#include "include/memory.h"
#include "include/sim_main.h"
#include "include/monitor.h"

#include <stdio.h>
#include <assert.h>




int main(int argc, char** argv) {

    monitor_init(argc, argv);

    sim_init(argc, argv);

    reset(SIM_MODULE_NAME, 1);

#ifdef USE_TESTBENCH
    while(!contextp->gotFinish() && sim_time >= 0){   
        dump_wave(SIM_MODULE_NAME);
    }
#else
    while(!contextp->gotFinish() && sim_time >= 0){
        single_cycle(SIM_MODULE_NAME);
    }
#endif

    tfp->close();
    return 0;
}                                                     
