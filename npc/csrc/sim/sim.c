#include "../include/sim.h"

int sim_time = SIM_TIME_MAX;

VerilatedContext* contextp = NULL;
VerilatedFstC* tfp = NULL;
SIM_MODULE* SIM_MODULE_NAME;

void halt(void){
    printf("\nProgram halt at clock time %d.\n", SIM_TIME_MAX - sim_time);
    dump_wave(SIM_MODULE_NAME);
    if(SIM_MODULE_NAME->trap_flag == 0){
        printf("HIT GOOD TRAP.\n");
    }else{
        printf("HIT BAD TRAP.\n");
    }
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

bool is_sim_continue(void){
    bool ret = (!contextp->gotFinished() && sim_time >= 0);
    return ret;
}

void tfp_close(void){
    tfp->close();
}