#include "common.h"
#include "perf_cnt.h"

static int perf_cnt [CNT_NUM] = {0};

static const char *perf_cnt_name[CNT_NUM] = {
    // IFU Group
    [IFU_FETCH]       = "IFU_FETCH",
    [IFU_FETCH_FLASH] = "IFU_FETCH_FLASH",
    [IFU_FETCH_SRAM]  = "IFU_FETCH_SRAM",
    [IFU_FETCH_SDRAM] = "IFU_FETCH_SDRAM",

    // IDU Group - Types
    [IDU_DECODE]      = "IDU_DECODE",
    [IDU_CALC_TYPE]   = "IDU_CALC_TYPE",
    [IDU_IMM_TYPE]    = "IDU_IMM_TYPE",
    [IDU_BRANCH_TYPE] = "IDU_BRANCH_TYPE",
    [IDU_LOAD_TYPE]   = "IDU_LOAD_TYPE",
    [IDU_SAVE_TYPE]   = "IDU_SAVE_TYPE",
    [IDU_CSR_TYPE]    = "IDU_CSR_TYPE",

    // IDU Group - Cycles
    [IDU_CALC_CYCLE]  = "IDU_CALC_CYCLE",
    [IDU_IMM_CYCLE]   = "IDU_IMM_CYCLE",
    [IDU_BRANCH_CYCLE] = "IDU_BRANCH_CYCLE",
    [IDU_LOAD_CYCLE]  = "IDU_LOAD_CYCLE",
    [IDU_SAVE_CYCLE]  = "IDU_SAVE_CYCLE",
    [IDU_CSR_CYCLE]   = "IDU_CSR_CYCLE",

    // LSU Group
    [LSU_GET]         = "LSU_GET",
    [LSU_WRITE]       = "LSU_WRITE",

    // EXU Group
    [EXU_FINISH_CALC] = "EXU_FINISH_CALC"
};

extern "C" void perf_cnt_add(int cnt_id, int num) {
    Assert(cnt_id < CNT_NUM, "Wrong perf cnt id");
    perf_cnt[cnt_id] += num;
}

int perf_cnt_get_val(int cnt_id) {
    Assert(cnt_id < CNT_NUM, "Wrong perf cnt id");
    return perf_cnt[cnt_id];
}

const char *perf_cnt_get_name(int cnt_id) {
    Assert(cnt_id < CNT_NUM, "Wrong perf cnt id");
    return perf_cnt_name[cnt_id];
}

void perf_cnt_print_all(void) {
    for(int i = 0; i < CNT_NUM; i++) {
        simple_Log("pref cnt %s = %d", perf_cnt_name[i], perf_cnt[i]);
    }
}

void print_perf_summary(void) {
    simple_Log("IFU fetch inst time: %d FLASH, %d SRAM, %d SDRAM", 
                perf_cnt_get_val(IFU_FETCH_FLASH), perf_cnt_get_val(IFU_FETCH_SRAM),
                perf_cnt_get_val(IFU_FETCH_SDRAM));

    if (perf_cnt_get_val(IDU_CALC_TYPE) > 0) {
        simple_Log("INST calc   time %7d, cycle %7d, %8.2f cycle/inst", 
                    perf_cnt_get_val(IDU_CALC_TYPE), perf_cnt_get_val(IDU_CALC_CYCLE),
                    (float)perf_cnt_get_val(IDU_CALC_CYCLE) / (float)perf_cnt_get_val(IDU_CALC_TYPE));
    }
    if (perf_cnt_get_val(IDU_IMM_TYPE) > 0) {
        simple_Log("INST imm    time %7d, cycle %7d, %8.2f cycle/inst", 
                    perf_cnt_get_val(IDU_IMM_TYPE), perf_cnt_get_val(IDU_IMM_CYCLE),
                    (float)perf_cnt_get_val(IDU_IMM_CYCLE) / (float)perf_cnt_get_val(IDU_IMM_TYPE));
    }
    if (perf_cnt_get_val(IDU_BRANCH_TYPE) > 0) {
        simple_Log("INST branch time %7d, cycle %7d, %8.2f cycle/inst", 
                    perf_cnt_get_val(IDU_BRANCH_TYPE), perf_cnt_get_val(IDU_BRANCH_CYCLE),
                    (float)perf_cnt_get_val(IDU_BRANCH_CYCLE) / (float)perf_cnt_get_val(IDU_BRANCH_TYPE));
    }
    if (perf_cnt_get_val(IDU_LOAD_TYPE) > 0) {
        simple_Log("INST load   time %7d, cycle %7d, %8.2f cycle/inst", 
                    perf_cnt_get_val(IDU_LOAD_TYPE), perf_cnt_get_val(IDU_LOAD_CYCLE),
                    (float)perf_cnt_get_val(IDU_LOAD_CYCLE) / (float)perf_cnt_get_val(IDU_LOAD_TYPE));
    }
    if (perf_cnt_get_val(IDU_SAVE_TYPE) > 0) {
        simple_Log("INST save   time %7d, cycle %7d, %8.2f cycle/inst", 
                    perf_cnt_get_val(IDU_SAVE_TYPE), perf_cnt_get_val(IDU_SAVE_CYCLE),
                    (float)perf_cnt_get_val(IDU_SAVE_CYCLE) / (float)perf_cnt_get_val(IDU_SAVE_TYPE));
    }
    if (perf_cnt_get_val(IDU_CSR_TYPE) > 0) {
        simple_Log("INST csr    time %7d, cycle %7d, %8.2f cycle/inst", 
                    perf_cnt_get_val(IDU_CSR_TYPE), perf_cnt_get_val(IDU_CSR_CYCLE),
                    (float)perf_cnt_get_val(IDU_CSR_CYCLE) / (float)perf_cnt_get_val(IDU_CSR_TYPE));
    }
}