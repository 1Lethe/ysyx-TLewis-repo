#include "sim.h"
#include "utils.h"

int sim_time = SIM_TIME_MAX;

VerilatedContext* contextp = NULL;
VerilatedFstC* tfp = NULL;
SIM_MODULE* SIM_MODULE_NAME;

void halt(void){
    printf("Program halt at clock time %d.PC = 0x%x.\n", SIM_TIME_MAX - sim_time, SIM_MODULE_NAME->pc);
    dump_wave(SIM_MODULE_NAME);
    if(SIM_MODULE_NAME->trap_flag == 0){
        printf("NPC: %s\n", ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN));
    }else{
        printf("NPC: %s\n", ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED));
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
    bool ret = (!contextp->gotFinish() && sim_time >= 0);
    if(!ret){
        printf("Sim stop.This may be due to insuffcient sim_time. If so, increase SIM_TIME marco. now = %d\n", SIM_TIME_MAX);
    }
    return ret;
}

void tfp_close(void){
    tfp->close();
}