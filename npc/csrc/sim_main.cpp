#include "Vtop.h"                                                      
#include "verilated.h"                                                 
#include "verilated_fst_c.h"                                           
#include <stdio.h>                                                     
#include <stdlib.h>                                                    
#include <assert.h>                   

#define SIM_MODULE_NAME top

VerilatedContext* contextp = NULL;
VerilatedFstC* tfp = NULL;
Vtop* SIM_MODULE_NAME;

int sim_time = 50;

void sim_init(int argc, char** argv){
    contextp = new VerilatedContext;                 
    contextp->commandArgs(argc, argv);                                 
    SIM_MODULE_NAME = new Vtop{contextp};                                    
                                                                       
    tfp = new VerilatedFstC;                            
    contextp->traceEverOn(true);                                       
    SIM_MODULE_NAME->trace(tfp, 99);  // Trace 99 levels of hierarchy (or see below)
    tfp->open("wave/wave.fst");                                             
}

void dump_wave(void){
    SIM_MODULE_NAME->eval();
    tfp->dump(contextp->time());                  
    contextp->timeInc(1);                         
    sim_time--;                                   
}

void single_cycle(Vtop* top){
    top->buttom = 0;top->eval();dump_wave();
    top->buttom = 1;top->eval();dump_wave();
}

void reset(Vtop* top, int n){
    top->rst = 1;
    while(n-- > 0) single_cycle(top);
    top->rst = 0;
}

int main(int argc, char** argv) {                                      
    
    sim_init(argc, argv);                                                     
    
    reset(SIM_MODULE_NAME, 10);
    
    while(!contextp->gotFinish() && sim_time >= 0){   
        single_cycle(SIM_MODULE_NAME);
    }   
    tfp->close();                                     
    return 0;                                         
}                                                     
