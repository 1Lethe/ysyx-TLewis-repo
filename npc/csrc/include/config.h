#ifndef __CONFIG_H
#define __CONFIG_H

// TODO: 适配menuconfig

//#define EN_ITRACE 1
//#define EN_MTRACE 1
//#define EN_FTRACE 1
//#define EN_DTRACE 1
#define EN_DIFFTEST 1
#define EN_DEVICE 1
//#define EN_DUMP_WAVE 1
#define CONFIG_MEM_RANDOM 1

// 每N条指令输出一次，以观察程序运行进度(默认为N=百万条)
#define EN_PRINT_EVERY_INST 1
#define PRINT_INST_TIME     1000000
// 当程序指令保持N个周期时，报错并停止
#define EN_STOP_WHEN_DEADLOOP   1
#define STOP_DEADLOOP_MAX       1000

// 通过检测对mvendorid CSR的读操作判断AM是否完成TRM init
#define DETECT_TRM_INIT 1

#ifdef DETECT_TRM_INIT

// 显式检查栈溢出
// 在接入SoC时，我们将栈分配在SRAM中，
// 而发生线程切换时sp也可能指向数据段，即需要检查栈指针sp的正确位置 >= STACK_BOTTOM
// 但注意ssbl也分配在SRAM中，但正常情况栈应该可以安全的覆盖这部分(?)
#define EN_CHECK_STACK_OVERFLOW 1
#define STACK_BOTTOM SRAM_BASE
#define STACK_TOP    SRAM_BASE + SRAM_SIZE

#ifdef EN_DUMP_WAVE
// 启用仅当TRM init完成后才记录波形功能，减小运行负担，不适用裸机程序 (依赖EN_DUMP_WAVE & DETECT_TRM_INIT)
#define EN_DUMP_WAVE_AFTER_INIT
#endif /* EN_DUMP_WAVE */

#ifdef EN_DIFFTEST
// 启用仅当TRM init完成后才开始difftest,适合调试功能bug时 (依赖EN_DIFFTEST & DETECT_TRM_INIT)
#define EN_DIFFTEST_AFTER_INIT
#endif /* EN_DIFFTEST */

#ifdef USE_NVBOARD
#define EN_UPDATE_NVBOARD_AFTER_INIT
#endif /* USE_NVBOARD */

#endif /* DETECT_TRM_INIT */

#define USE_SOC 1

// 启用硬件的内存映射，关闭仿真环境的sim_pmem_write映射
#define EN_MMIO_HARDWARE

// We use RV32E now, so we need to match number of regs in difftest
#define CONFIG_RVE 1

#endif