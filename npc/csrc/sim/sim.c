#include "common.h"
#include "sim.h"
#include "cpu-exec.h"

static bool sim_stop_flag = false;

VerilatedContext* contextp = NULL;
VerilatedFstC* tfp = NULL;
SIM_MODULE* SIM_MODULE_NAME;

void halt(void){
    if(SIM_MODULE_NAME->trap_flag == 0){
        Log("NPC: %s PC = 0x%x", ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN), SIM_MODULE_NAME->pc);
    }else{
        Log("NPC: %s PC = 0x%x", ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED), SIM_MODULE_NAME->pc);
    }
    sim_stop_flag = true;
}

void sim_init(int argc, char** argv){
    contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    SIM_MODULE_NAME = new SIM_MODULE{contextp};
#ifdef EN_DUMP_WAVE
    tfp = new VerilatedFstC;
    contextp->traceEverOn(true);
    SIM_MODULE_NAME->trace(tfp, 99);  // Trace 99 levels of hierarchy (or see below)
    tfp->open("/home/tonglewis/ysyx-workbench/npc/wave/wave.fst");
#endif
}

void dump_wave(SIM_MODULE* top){
#ifdef EN_DUMP_WAVE
    tfp->dump(contextp->time());
    contextp->timeInc(1);
#endif
}

bool is_sim_continue(void){
    bool ret = (!contextp->gotFinish() && sim_stop_flag == false);
    if(!ret){
        Log("Sim stop.cycle time = %ld", get_cycle_time());
    }
    return ret;
}

void tfp_close(void){
    tfp->close();
}

extern "C" void sim_hardware_fault_handle(int NO, int arg0) {
    if(NO == 1) {
        Assert(0, "ACCESS MEMORY FAULT 0x%x.ABORT.", arg0);
    }else {
        assert(0);
    }
}