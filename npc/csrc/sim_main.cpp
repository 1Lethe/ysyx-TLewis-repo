#include "Vkeyboard_sim.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

//Still need to change SIM_TOPNAME in makefile!
#define SIM_MODULE Vkeyboard_sim
#define SIM_MODULE_NAME keyboard_sim

//sim time
int sim_time = 50;

VerilatedContext* contextp = NULL;
VerilatedFstC* tfp = NULL;
SIM_MODULE* top;

void sim_init(int argc, char** argv){
    contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    SIM_MODULE_NAME = new SIM_MODULE{contextp};

    tfp = new VerilatedFstC;
    contextp->traceEverOn(true);
    SIM_MODULE_NAME->trace(tfp, 99);  // Trace 99 levels of hierarchy (or see below)
    tfp->open("wave/wave.fst");
}
#if 0
void dump_wave(SIM_MODULE* top){
    top->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);
    sim_time--;
}

void single_cycle(SIM_MODULE* top){
    top->clk = 0;top->eval();
    top->clk = 1;top->eval();
}

void reset(SIM_MODULE* top, int n){
    top->rst = 1;
    while(n-- > 0) single_cycle(top);
    top->rst = 0;
}
#endif
int main(int argc, char** argv) {                                      
    
    sim_init(argc, argv);
    reset(SIM_MODULE_NAME,10);
    while(!contextp->gotFinish() && sim_time >= 0){   
        dump_wave(SIM_MODULE_NAME);
    }   
    tfp->close();
    return 0;
}                                                     
