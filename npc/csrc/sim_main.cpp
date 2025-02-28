//Still need to change this #include and SIM_NAME in makefile to change sim module.

#include "cpu-exec.h"
#include "memory.h"
#include "sim_main.h"
#include "monitor.h"
#include "sim.h"
#include "sdb.h"
#include "debug.h"
#include "trace.h"

#include <stdio.h>

extern SIM_MODULE* SIM_MODULE_NAME;

int main(int argc, char** argv) {

    sim_init(argc, argv);
    
    reset(SIM_MODULE_NAME, 10);

    monitor_init(argc, argv);

#ifdef USE_TESTBENCH
    while(!contextp->gotFinish() && sim_time >= 0){   
        dump_wave(SIM_MODULE_NAME);
    }
#else
    sdb_mainloop();
#endif

    IFDEF(EN_ITRACE, iring_free());
    IFDEF(EN_DUMP_WAVE, tfp_close());
    return 0;
}                                                     
