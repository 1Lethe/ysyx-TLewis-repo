#include "common.h"
#include "sim.h"

int sim_time = SIM_TIME_MAX;

VerilatedContext* contextp = NULL;
VerilatedVcdC* tfp = NULL;
SIM_MODULE* SIM_MODULE_NAME;

void halt(void){
    Log("Program halt at clock time %d.", SIM_TIME_MAX - sim_time);
    dump_wave(SIM_MODULE_NAME);
    if(SIM_MODULE_NAME->trap_flag == 0){
        Log("NPC: %s PC = 0x%x", ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN), SIM_MODULE_NAME->pc);
    }else{
        Log("NPC: %s PC = 0x%x", ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED), SIM_MODULE_NAME->pc);
    }
    sim_time = 0;
}

void sim_init(int argc, char** argv){
    contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    SIM_MODULE_NAME = new SIM_MODULE{contextp};
#ifdef EN_DUMP_WAVE
    tfp = new VerilatedVcdC;
    contextp->traceEverOn(true);
    SIM_MODULE_NAME->trace(tfp, 99);  // Trace 99 levels of hierarchy (or see below)
    tfp->open("/home/tonglewis/ysyx-workbench/npc/wave/wave.vcd");
#endif
}

void dump_wave(SIM_MODULE* top){
#ifdef EN_DUMP_WAVE
    tfp->dump(contextp->time());
    contextp->timeInc(1);
#endif
}

bool is_sim_continue(void){
    bool ret = (!contextp->gotFinish() && sim_time >= 0);
    if(!ret){
        Log("Sim stop.This may be due to insuffcient sim_time. If so, increase SIM_TIME marco. now = %d", 
            SIM_TIME_MAX);
    }
    return ret;
}

void tfp_close(void){
    tfp->close();
}