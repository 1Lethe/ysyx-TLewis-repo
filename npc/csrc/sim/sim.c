#include "common.h"
#include "sim.h"
#include "cpu-exec.h"
#include "svdpi.h"
#include "difftest.h"

static bool sim_stop_flag = false;

VerilatedContext* contextp = NULL;
VerilatedFstC* tfp = NULL;
SIM_MODULE* SIM_MODULE_NAME;

CPU_state cpu;

void halt(void){
    if(cpu.gpr[10] == 0){
        Log("NPC: %s PC = 0x%x", ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN), cpu.pc);
    }else{
        Log("NPC: %s PC = 0x%x", ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED), cpu.pc);
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

void init_scope(void) {
    svScope scope = svGetScopeFromName("TOP.ysyxSoCFull.asic.cpu.cpu");
    svSetScope(scope);
}

void update_simenv_cpu_state(void) {
    for(int i = 0; i < RISCV_GPR_NUM; i++) {
        cpu.gpr[i] = get_rf_value(i);
    }
    cpu.mstatus = get_csr_value(CSR_MSTATUS);
    cpu.mtvec = get_csr_value(CSR_MTVEC);
    cpu.mepc = get_csr_value(CSR_MEPC);
    cpu.mcause = get_csr_value(CSR_MCAUSE);
    cpu.pc = get_pc_value();
}

extern "C" void sim_hardware_fault_handle(int NO, int arg0) {
    switch (NO)
    {
    case FAULT_ADDR_DECODE:
        Assert(0, "Physical Address Decode Error(MMIO/Memory not mapped). ADDR:0x%08x", arg0);
        break;
    case FAULT_ADDR_MISALIGN:
        Assert(0, "Load/Store Address Misalignment Exception. ADDR:0x%08x", arg0);
        break;
    case FAULT_AXI_RESP:
        Assert(0, "AXI Bus Transaction Failed (xRESP != OKAY). ADDR:0x%08x", arg0);
        break;
    default:
        Assert(0, "Unknown Hardware Fault Triggered. Fault type ID:%d, DATA: 0x%08x", NO, arg0);
        break;
    }
}

extern "C" void sim_difftest_skip(void) {
    difftest_skip_ref();
}