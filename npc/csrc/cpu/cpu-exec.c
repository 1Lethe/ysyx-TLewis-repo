#include "sim_main.h"
#include "cpu-exec.h"
#include "memory.h"

void single_cycle(SIM_MODULE* top){
    top->clk = 0;top->eval();dump_wave(top);
    top->clk = 1;top->eval();
    if(top->rst != 1){
        top->pmem = pmem_read(top->pc, 4);top->eval();
    }
    dump_wave(top);
    sim_time--;
}

void reset(SIM_MODULE* top, int n){
    top->rst = 1; top->eval();
    while(n-- > 0) single_cycle(top);
    top->rst = 0; top->eval();
}
