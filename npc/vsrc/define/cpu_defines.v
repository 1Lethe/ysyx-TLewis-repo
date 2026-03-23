`ifndef ysyx_24120013__CPU_DEFINES
`define ysyx_24120013__CPU_DEFINES

`define ysyx_24120013_ALUOP_WIDTH 15
`define ysyx_24120013_BRANCH_WIDTH 8
`define ysyx_24120013_ECU_WIDTH  4
`define ysyx_24120013_ZERO_WIDTH 4 
`define ysyx_24120013_SEXT_WIDTH 4 

`define ysyx_24120013_CSR_ADDR_WIDTH 12
`define ysyx_24120013_MSTATUS 12'h300
`define ysyx_24120013_MTVEC   12'h305
`define ysyx_24120013_MEPC    12'h341
`define ysyx_24120013_MCAUSE  12'h342

`define ysyx_24120013_MVENDORID 12'hF11
`define ysyx_24120013_MARCHID   12'hF12

//`define ysyx_24120013_USE_CPP_SIM_ENV

`ifdef ysyx_24120013_USE_CPP_SIM_ENV
// === IFU Group ===
`define ysyx_24120013_PERF_IFU_FETCH        0
`define ysyx_24120013_PERF_IFU_FETCH_FLASH  1
`define ysyx_24120013_PERF_IFU_FETCH_SRAM   2
`define ysyx_24120013_PERF_IFU_FETCH_SDRAM  3

// === IDU Group - Types ===
`define ysyx_24120013_PERF_IDU_DECODE       4
`define ysyx_24120013_PERF_IDU_CALC_TYPE    5
`define ysyx_24120013_PERF_IDU_IMM_TYPE     6
`define ysyx_24120013_PERF_IDU_BRANCH_TYPE  7
`define ysyx_24120013_PERF_IDU_LOAD_TYPE    8
`define ysyx_24120013_PERF_IDU_SAVE_TYPE    9
`define ysyx_24120013_PERF_IDU_CSR_TYPE     10

// === IDU Group - Cycles ===
`define ysyx_24120013_PERF_IDU_CALC_CYCLE   11
`define ysyx_24120013_PERF_IDU_IMM_CYCLE    12
`define ysyx_24120013_PERF_IDU_BRANCH_CYCLE 13
`define ysyx_24120013_PERF_IDU_LOAD_CYCLE   14
`define ysyx_24120013_PERF_IDU_SAVE_CYCLE   15
`define ysyx_24120013_PERF_IDU_CSR_CYCLE    16

// === LSU Group ===
`define ysyx_24120013_PERF_LSU_GET          17
`define ysyx_24120013_PERF_LSU_WRITE        18

// === EXU Group ===
`define ysyx_24120013_PERF_EXU_FINISH_CALC  19
`endif

`endif