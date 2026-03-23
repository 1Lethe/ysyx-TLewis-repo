#ifndef __PERF_CNT__
#define __PERF_CNT__

// NOTE: 在verilog中硬编码，如要修改还需要修改vsrc的相关代码!
typedef enum {
    // IFU Group
    IFU_FETCH        = 0,
    IFU_FETCH_FLASH  = 1,
    IFU_FETCH_SRAM   = 2,
    IFU_FETCH_SDRAM  = 3,

    // IDU Group
    IDU_DECODE       = 4,
    IDU_CALC_TYPE    = 5,
    IDU_IMM_TYPE     = 6,
    IDU_BRANCH_TYPE  = 7,
    IDU_LOAD_TYPE    = 8,
    IDU_SAVE_TYPE    = 9,
    IDU_CSR_TYPE     = 10,

    IDU_CALC_CYCLE   = 11,
    IDU_IMM_CYCLE    = 12,
    IDU_BRANCH_CYCLE = 13,
    IDU_LOAD_CYCLE   = 14,
    IDU_SAVE_CYCLE   = 15,
    IDU_CSR_CYCLE    = 16,

    // LSU Group
    LSU_GET          = 17,
    LSU_WRITE        = 18,

    // EXU Group
    EXU_FINISH_CALC  = 19,

    CNT_NUM
} PERF_CNT_TYPE;

int perf_cnt_get_val(int cnt_id);
const char *perf_cnt_get_name(int cnt_id);
void perf_cnt_print_all(void);
void print_perf_summary(void);

#endif