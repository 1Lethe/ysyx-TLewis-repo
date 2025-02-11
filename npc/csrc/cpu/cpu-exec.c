#include "cpu-exec.h"
#include "difftest.h"

bool difftest_init_flag = false;
extern int sim_time;

extern char *diff_so_file;
extern int difftest_port;
extern long img_size;

void single_cycle(SIM_MODULE* top){
    top->clk = 0;top->eval();dump_wave(top);
    top->clk = 1;top->eval();dump_wave(top);
    sim_time--;
}

void cycle(SIM_MODULE* top, uint64_t n){
    static bool diff_skip = false;

    for(int i = 0; (i < n) && (is_sim_continue()); i++){
        single_cycle(top);

        if(!difftest_init_flag){
            init_difftest(top, diff_so_file, img_size, difftest_port);
            difftest_init_flag = true;
        }
        if(!diff_skip){
            diff_skip = true;
        }else{
            difftest_step(top, top->pc, top->pc);
        }
        iring(top->pc, pmem_read(top->pc, 4));
        //ftrace(top->pc);
    }
}

void reset(SIM_MODULE* top, int n){
    top->rst = 1; top->eval();
    while(n-- > 0) single_cycle(top);
    top->rst = 0; top->eval();
}
