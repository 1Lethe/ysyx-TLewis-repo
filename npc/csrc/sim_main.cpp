#include "Vtop.h"                                                      
#include "verilated.h"                                                 
#include "verilated_fst_c.h"                                           
#include <stdio.h>                                                     
#include <stdlib.h>                                                    
#include <assert.h>                   

VerilatedContext* contextp = NULL;
VerilatedFstC* tfp = NULL;
Vtop* top;

int sim_time = 50;

void sim_init(int argc, char** argv){
    contextp = new VerilatedContext;                 
    contextp->commandArgs(argc, argv);                                 
    top = new Vtop{contextp};                                    
                                                                       
    tfp = new VerilatedFstC;                            
    contextp->traceEverOn(true);                                       
    top->trace(tfp, 99);  // Trace 99 levels of hierarchy (or see below)
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
            
        top->alu_command = 0;top->inA = 1;top->inB = 1;dump_wave();
        top->inA = -1;top->inB = -1;dump_wave(); 
        top->inA = -7;top->inB = -7;dump_wave();

        top->alu_command = 1;top->inA = 1;top->inB = 1;dump_wave();
        top->inA = -7;top->inB = 7;dump_wave(); 
        top->inA = 7;top->inB = 1;dump_wave();

        top->alu_command = 2;top->inA = 7;top->inB = 0;dump_wave();
        top->alu_command = 3;top->inA = 3;top->inB = 5;dump_wave();
        top->alu_command = 4;top->inA = 4;top->inB = -3;dump_wave();
        top->alu_command = 5;top->inA = -7;top->inB = -1;dump_wave();

        top->alu_command = 6;top->inA = 7;top->inB = 5;dump_wave();
        top->inA = 7;top->inB = -5;dump_wave();
        top->inA = -7;top->inB = 7;dump_wave();
        top->inA = -5;top->inB = -7;dump_wave();
        top->inA = 1;top->inB = -5;dump_wave();
        top->inA = -1;top->inB = -1;dump_wave();

        top->alu_command = 7;top->inA = 3;top->inB = 3;dump_wave();
        top->inA = -7;top->inB = 3;dump_wave();
    }   
    tfp->close();                                     
    return 0;                                         
}                                                     
