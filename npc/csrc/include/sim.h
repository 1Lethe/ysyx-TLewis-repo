
#ifndef __SIM_H
#define __SIM_H

#include "verilated_fst_c.h"
#include "VysyxSoCFull__Dpi.h"

#include "sim_main.h"

// sim fault code
#define FAULT_ADDR_DECODE   1  // 地址解码失败 (No device mapped)
#define FAULT_ADDR_MISALIGN 2  // 地址不对齐 (Misaligned access)
#define FAULT_AXI_RESP      3  // AXI总线响应错误 (Bus Error)

void sim_init(int argc, char **argv);
void dump_wave(SIM_MODULE* top);
bool is_sim_continue(void);
void update_simenv_cpu_state(void);
void tfp_close(void);

#endif