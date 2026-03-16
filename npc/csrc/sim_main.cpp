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

int main(int argc, char** argv) {

    sim_init(argc, argv);
    
    reset(SIM_MODULE_NAME, 10);

    monitor_init(argc, argv);

    sdb_mainloop();

    IFDEF(EN_ITRACE, iring_free());
    IFDEF(EN_DUMP_WAVE, tfp_close());
    IFDEF(USE_NVBOARD, nvboard_quit());
    return 0;
}                                                     
