//Still need to change this #include and SIM_NAME in makefile to change sim module.

#include "include/cpu-exec.h"
#include "include/memory.h"
#include "include/sim_main.h"
#include "include/monitor.h"
#include "include/sim.h"

#include <stdio.h>
void halt(void){
    printf("\nProgram halt at clock time %d.\n", SIM_TIME_MAX - sim_time);
    dump_wave(SIM_MODULE_NAME);
    if(SIM_MODULE_NAME->trap_flag == 0){
        printf("HIT GOOD TRAP.\n");
    }else{
        printf("HIT BAD TRAP.\n");
    }
    sim_time = 0;
}

int main(int argc, char** argv) {

    monitor_init(argc, argv);

    sim_init(argc, argv);

    reset(SIM_MODULE_NAME, 1);

#ifdef USE_TESTBENCH
    while(!contextp->gotFinish() && sim_time >= 0){   
        dump_wave(SIM_MODULE_NAME);
    }
#else
    while(is_sim_continue()){
        single_cycle(SIM_MODULE_NAME);
    }
#endif

    tfp_close();
    return 0;
}                                                     
