#include "Vtop.h"                                                      
#include "verilated.h"                                                 
#include "verilated_fst_c.h"                                           
#include <stdio.h>                                                     
#include <stdlib.h>                                                    
#include <assert.h>                   

VerilatedContext* contextp = NULL;
VerilatedFstC* tfp = NULL;
Vtop* RandomGen;

int sim_time = 50;

void sim_init(int argc, char** argv){
    contextp = new VerilatedContext;                 
    contextp->commandArgs(argc, argv);                                 
    RandomGen = new Vtop{contextp};                                    
                                                                       
    tfp = new VerilatedFstC;                            
    contextp->traceEverOn(true);                                       
    RandomGen->trace(tfp, 99);  // Trace 99 levels of hierarchy (or see below)
    tfp->open("wave/wave.fst");                                             
}

void dump_wave(void){
    top->eval();
    tfp->dump(contextp->time());                  
    contextp->timeInc(1);                         
    sim_time--;                                   
}

void single_cycle(Vtop* top){
    top->clk = 0;top->eval();
    top->clk = 1;top->eval();
}

void reset(Vtop* top, int n){
    top->rst = 1;
    while(n-- > 0) single_cycle(top);
    top->rst = 0;
}

int main(int argc, char** argv) {                                      
    
    sim_init(argc, argv);                                                     
    
    
    while(!contextp->gotFinish() && sim_time >= 0){   
            

    }   
    tfp->close();                                     
    return 0;                                         
}                                                     
