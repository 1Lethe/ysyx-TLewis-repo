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

int sim_time = SIM_TIME_MAX;

VerilatedContext* contextp = NULL;
VerilatedFstC* tfp = NULL;
SIM_MODULE* SIM_MODULE_NAME;

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

void sim_init(int argc, char** argv){
    contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    SIM_MODULE_NAME = new SIM_MODULE{contextp};

    tfp = new VerilatedFstC;
    contextp->traceEverOn(true);
    SIM_MODULE_NAME->trace(tfp, 99);  // Trace 99 levels of hierarchy (or see below)
    tfp->open("/home/tonglewis/ysyx-workbench/npc/wave/wave.fst");
}

void dump_wave(SIM_MODULE* top){
    tfp->dump(contextp->time());
    contextp->timeInc(1);
}

int main(int argc, char** argv) {

    monitor_init(argc, grgv);

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
