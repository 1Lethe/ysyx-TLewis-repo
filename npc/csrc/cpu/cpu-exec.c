#include "common.h"
#include "cpu-exec.h"
#include "difftest.h"

static uint64_t cycle_time = 0;

static uint64_t inst_exec_hit_time = 0;
static uint64_t inst_exec_time = 0;

static int one_inst_cycle_time = 0;

static bool trm_init_complete = false;

bool difftest_check_on = false;

extern char *diff_so_file;
extern long img_size;
extern int difftest_port;

void device_update();

#ifdef EN_DIFFTEST
void diff_check_switch (bool state) {
    difftest_check_on = state;
    if(state) {
        simple_Log("Difftest %s",ANSI_FMT("ON", ANSI_FG_GREEN));
    }else {
        simple_Log("Difftest %s",ANSI_FMT("OFF", ANSI_FG_RED));
    }
}
#endif

#ifdef DETECT_TRM_INIT

static void updata_trm_init_complete_flag (void) {
    if(read_trm_init_complete_flag()) {
        simple_Log("NPC detect mvendorid CSR read");
        simple_Log("NPC detect %s",ANSI_FMT("AM trm init COMPLETE", ANSI_FG_GREEN));
        trm_init_complete = true;

#if defined(EN_DUMP_WAVE) && defined(EN_DUMP_WAVE_AFTER_INIT) 
        trace_fst_init();
#endif

#if defined(EN_DIFFTEST) && defined(EN_DIFFTEST_AFTER_INIT) 
        diff_check_switch(true);
#endif
    }
}

#endif /* DETECT_TRM_INIT */

#ifdef EN_PRINT_EVERY_INST
static void print_exec_inst_time (int max) {
    if(inst_exec_time == max){
        inst_exec_hit_time += 1;
        inst_exec_time = 0;
        uint64_t inst_sum = inst_exec_time + inst_exec_hit_time * max;
        simple_Log("Hit %d inst record.Has exec %ld inst.", max, inst_sum);
    }
}
#endif

#ifdef STOP_DEADLOOP_MAX
static void inst_cycle_stop (void) {
    if(one_inst_cycle_time == STOP_DEADLOOP_MAX) {
        simple_Log("Inst not update for %d cycle.Sim stop.", STOP_DEADLOOP_MAX);
        assert_fail_msg();
        halt();
    }
}
#endif

#ifdef EN_CHECK_STACK_OVERFLOW
static void check_stack_overflow (uint32_t sp) {
    if(sp < STACK_BOTTOM) {
        Log("SP = 0x%08x invalid (0 ,0x%08x) . (set in SRAM), might stack overflow.", sp, STACK_BOTTOM);
        assert_fail_msg();
        halt();
    }
}
#endif

static void dump_wave_wrapper (SIM_MODULE* top) {
#ifdef EN_DUMP_WAVE_AFTER_INIT
    if(trm_init_complete) dump_wave(top);
#else
    dump_wave(top);
#endif
}

static void update_nvboard_wrapper(void) {
#ifdef EN_UPDATE_NVBOARD_AFTER_INIT
    if(trm_init_complete) nvboard_update();
#else
    nvboard_update();
#endif
}

void single_cycle(SIM_MODULE* top){
    top->clock = 0;top->eval();
    IFDEF(EN_DUMP_WAVE, dump_wave_wrapper(top);)
    top->clock = 1;top->eval();
    IFDEF(EN_DUMP_WAVE, dump_wave_wrapper(top);)
}

void cycle(SIM_MODULE* top, uint64_t n){
    for(int i = 0; (i < n) && (is_sim_continue()); i++){
        single_cycle(top);
        cycle_time++;
        update_simenv_cpu_state();

        if(is_exec_new_inst()){
            inst_exec_time += 1; 
            IFDEF(DETECT_TRM_INIT, if(!trm_init_complete) updata_trm_init_complete_flag();)
            IFDEF(EN_PRINT_EVERY_INST , print_exec_inst_time(PRINT_INST_TIME);)
            IFDEF(STOP_DEADLOOP_MAX, one_inst_cycle_time = 0;)
            IFDEF(EN_CHECK_STACK_OVERFLOW, if(trm_init_complete) check_stack_overflow(cpu.gpr[2]);)
#ifdef EN_DIFFTEST
            if(difftest_check_on) {
                if(!difftest_step(cpu.pc, cpu.pc)){
                    assert_fail_msg();
                    halt();
                }
            } else {
                difftest_step_noncheck();
            }
#endif
        }else{
            IFDEF(STOP_DEADLOOP_MAX,one_inst_cycle_time++; inst_cycle_stop();)
        }
        IFDEF(EN_ITRACE, iring(cpu.pc, pmem_read(cpu.pc, 4)));
        IFDEF(EN_FTRACE, ftrace(cpu.pc));
        device_update();
        IFDEF(USE_NVBOARD, update_nvboard_wrapper());
    }
}

uint64_t get_cycle_time(void) {
    return cycle_time;
}

uint64_t get_inst_num(void) {
    return inst_exec_time;
}

// NOTE: 在这里注意Verilog的冒险行为！即若在时钟上升沿修改数据，会发生数据冒险，结果往往不正常。
void reset(SIM_MODULE* top, int n){
    top->reset = 1; top->eval();
    while(n-- > 0) single_cycle(top);
    top->reset = 0; top->eval(); 
}
