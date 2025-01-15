//Still need to change this #include and SIM_ysyx_24120013_topNAME in makefile to change sim module.
#include "Vysyx_24120013_top.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include "npcsrc/memory.h"
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

//If you want to use testbench just keep this #define otherwise delete it
//#define USE_TESTBENCH

#define SIM_MODULE Vysyx_24120013_top
#define SIM_MODULE_NAME top

//sim time
int sim_time = 50;

VerilatedContext* contextp = NULL;
VerilatedFstC* tfp = NULL;
SIM_MODULE* SIM_MODULE_NAME;

void sim_init(int argc, char** argv){
    contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    SIM_MODULE_NAME = new SIM_MODULE{contextp};

    tfp = new VerilatedFstC;
    contextp->traceEverOn(true);
    SIM_MODULE_NAME->trace(tfp, 99);  // Trace 99 levels of hierarchy (or see below)
    tfp->open("wave/wave.fst");
}

void dump_wave(SIM_MODULE* top){
    top->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);
#ifndef USE_TESTBENCH
    sim_time--;
#endif
}

#ifndef USE_TESTBENCH
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

#ifdef USE_TESTBENCH
    while(!contextp->gotFinish()){   
        dump_wave(SIM_MODULE_NAME);
    }
#endif
    //if not use testbench HERE
#ifndef USE_TESTBENCH
    while(!contextp->gotFinish() && sim_time >= 0){
        mem_out_of_bound(top->pc);
        top->pmem = pmem_read(top->pc);
        dump_wave(SIM_MODULE_NAME);
    }
#endif

    tfp->close();
    return 0;
}                                                     
