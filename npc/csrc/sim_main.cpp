//Still need to change this #include and SIM_NAME in makefile to change sim module.
#include "Vysyx_24120013_top.h"
#include "verilated.h"
#include "verilated_fst_c.h"
#include "Vysyx_24120013_top__Dpi.h"

#include "include/memory.h"
#include "include/sim_main.h"

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <getopt.h>

char *log_file = NULL;
char *diff_so_file = NULL;
char *img_file = NULL;
int difftest_port = 1234;

int sim_time = SIM_TIME_MAX;

VerilatedContext* contextp = NULL;
VerilatedFstC* tfp = NULL;
SIM_MODULE* SIM_MODULE_NAME;

void halt(void){
    printf("\nProgram Finished at clock time %d.\n", SIM_TIME_MAX - sim_time);
    dump_wave(SIM_MODULE_NAME);
    sim_time = 0;
}

void sim_init(int argc, char** argv){
    contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    SIM_MODULE_NAME = new SIM_MODULE{contextp};

    tfp = new VerilatedFstC;
    contextp->traceEverOn(true);
    SIM_MODULE_NAME->trace(tfp, 99);  // Trace 99 levels of hierarchy (or see below)
    tfp->open("/home/tonglewis/ysyx-workbench/npc/wave/wave.fst");
}

void dump_wave(SIM_MODULE* top){
    tfp->dump(contextp->time());
    contextp->timeInc(1);
}

#ifndef USE_TESTBENCH
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
#endif

static int parse_args(int argc, char *argv[]) {
    const struct option table[] = {
        {"log"      , required_argument, NULL, 'l'},
        {"diff"     , required_argument, NULL, 'd'},
        {"port"     , required_argument, NULL, 'p'},
        {"help"     , no_argument      , NULL, 'h'},
        {0          , 0                , NULL,  0 },
    };
    int o;
    while ( (o = getopt_long(argc, argv, "-bhl:d:p:", table, NULL)) != -1) {
    switch (o) {
        case 'p': sscanf(optarg, "%d", &difftest_port); break;
        case 'l': log_file = optarg; break;
        case 'd': diff_so_file = optarg; break;
        case 1: img_file = optarg; return 0;
        default:
            printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
            printf("\t-l,--log=FILE           output log to FILE\n");
            printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
            printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
            printf("\n");
            exit(0);
        }
    }
    return 0;
}

int main(int argc, char** argv) {                                      

    parse_args(argc, argv);
    load_img();

    sim_init(argc, argv);

    reset(SIM_MODULE_NAME, 1);

#ifdef USE_TESTBENCH
    while(!contextp->gotFinish() && sim_time >= 0){   
        dump_wave(SIM_MODULE_NAME);
    }
#endif
#ifndef USE_TESTBENCH
    while(!contextp->gotFinish() && sim_time >= 0){
        single_cycle(SIM_MODULE_NAME);
    }
#endif

    tfp->close();
    return 0;
}                                                     
