#include "common.h"
#include "cpu-exec.h"
#include "difftest.h"

bool difftest_init_flag = false;

extern char *diff_so_file;
extern int difftest_port;

void device_update();

void single_cycle(SIM_MODULE* top){
    top->clk = 0;top->eval();dump_wave(top);
    top->clk = 1;top->eval();dump_wave(top);
}

void cycle(SIM_MODULE* top, uint64_t n){
    static bool diff_skip = false;
    bool diff_flag = true;

    for(int i = 0; (i < n) && (is_sim_continue()); i++){
        single_cycle(top);
#ifdef EN_DIFFTEST
        if(!difftest_init_flag){
            extern long img_size;
            init_difftest(top, diff_so_file, img_size, difftest_port);
            difftest_init_flag = true;
        }
        if(!diff_skip){
            diff_skip = true;
        }else{
            diff_flag = difftest_step(top, top->pc, top->pc);
            if(diff_flag == false){
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

void reset(SIM_MODULE* top, int n){
    top->rst = 1; top->eval();
    while(n-- > 0) single_cycle(top);
    top->rst = 0; top->eval();
}
