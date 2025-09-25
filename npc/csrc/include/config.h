#ifndef __CONFIG_H
#define __CONFIG_H

//If you want to use testbench just keep this #define otherwise delete it
//#define USE_TESTBENCH

//#define EN_ITRACE 1
//#define EN_MTRACE 1
//#define EN_FTRACE 1
//#define EN_DTRACE 1
#define EN_DIFFTEST 1
#define EN_DEVICE 1
#define EN_DUMP_WAVE 1
#define CONFIG_MEM_RANDOM 1

// 启用硬件的内存映射，关闭仿真环境的sim_pmem_write映射
#define EN_MMIO_HARDWARE

// We use RV32E now, so we need to match number of regs in difftest
#define CONFIG_RVE 1

#endif