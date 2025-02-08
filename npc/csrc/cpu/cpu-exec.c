#include "cpu-exec.h"

extern int sim_time;

void single_cycle(SIM_MODULE* top){
    top->clk = 0;top->eval();dump_wave(top);
    top->clk = 1;top->eval();
    if(top->rst != 1){
        top->pmem = pmem_read(top->pc, 4);top->eval();
    }
    dump_wave(top);
    sim_time--;
}

void cycle(SIM_MODULE* top, uint64_t n){
    for(int i = 0; (i < n) && (is_sim_continue()); i++){
        single_cycle(top);

        if(top->rst != 1){
            itrace_record(top->pc, &top->pmem);
            ftrace(top->pc);
        }
    }
}

void reset(SIM_MODULE* top, int n){
    top->rst = 1; top->eval();
    while(n-- > 0) single_cycle(top);
    top->rst = 0; top->eval();
}
