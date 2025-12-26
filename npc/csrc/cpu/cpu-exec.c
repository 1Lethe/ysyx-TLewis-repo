#include "common.h"
#include "cpu-exec.h"
#include "difftest.h"

static uint64_t cycle_time = 0;

extern char *diff_so_file;
extern long img_size;
extern int difftest_port;

void device_update();

void single_cycle(SIM_MODULE* top){
    top->clock = 0;top->eval();dump_wave(top);
    top->clock = 1;top->eval();dump_wave(top);
}

void cycle(SIM_MODULE* top, uint64_t n){
    for(int i = 0; (i < n) && (is_sim_continue()); i++){
        single_cycle(top);
        cycle_time++;
#ifdef EN_DIFFTEST
        if(top->difftest_check_flag){
            if(!difftest_step(top, top->pc, top->pc)){
                assert_fail_msg();
                halt();
            }
        }
#endif
        IFDEF(EN_ITRACE, iring(top->pc, pmem_read(top->pc, 4)));
        IFDEF(EN_FTRACE, ftrace(top->pc));
        device_update();
    }
}

uint64_t get_cycle_time(void) {
    return cycle_time;
}

// NOTE: 在这里注意Verilog的冒险行为！即若在时钟上升沿修改数据，会发生数据冒险，结果往往不正常。
void reset(SIM_MODULE* top, int n){
    top->reset = 1; top->eval();
    while(n-- > 0) single_cycle(top);
    top->reset = 0; top->eval(); 
}
