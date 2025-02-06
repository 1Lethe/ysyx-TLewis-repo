//Still need to change this #include and SIM_NAME in makefile to change sim module.

#include "include/cpu-exec.h"
#include "include/memory.h"
#include "include/sim_main.h"
#include "include/monitor.h"
#include "include/sim.h"
#include "include/sdb.h"

#include <stdio.h>

extern SIM_MODULE* SIM_MODULE_NAME;

int main(int argc, char** argv) {

    monitor_init(argc, argv);

    sim_init(argc, argv);

    reset(SIM_MODULE_NAME, 10);

#ifdef USE_TESTBENCH
    while(!contextp->gotFinish() && sim_time >= 0){   
        dump_wave(SIM_MODULE_NAME);
    }
#else
    while(is_sim_continue()){
        sdb_mainloop();
    }
#endif

    tfp_close();
    return 0;
}                                                     
