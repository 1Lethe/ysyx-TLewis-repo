/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>
#include <cpu/cpu.h>
#include <difftest-def.h>
#include <memory/paddr.h>

struct diff_context_t{
  word_t gpr[MUXDEF(CONFIG_RVE, 16, 32)];
  word_t pc;
  word_t mstatus;
  word_t mtvec;
  word_t mepc;
  word_t mcause;
};

// store write memory trace to compare with DUT
struct diff_memtrace_t{
  word_t data;
  word_t address;
  int length;
  bool is_write_mem;
};

static struct diff_memtrace_t diff_memtrace_ref;

void diff_set_REF_memtrace_struct(word_t data, word_t address, word_t length) {
  if(length <= 0) {
    diff_memtrace_ref.data = 0;
    diff_memtrace_ref.address = 0;
    diff_memtrace_ref.length = 0;
    diff_memtrace_ref.is_write_mem = false;
  }else {
    diff_memtrace_ref.data = data;
    diff_memtrace_ref.address = address;
    diff_memtrace_ref.length = length;
    diff_memtrace_ref.is_write_mem = true;
  }
}

__EXPORT void difftest_memcpy(paddr_t addr, void *buf, size_t n, bool direction) {
  if(direction == DIFFTEST_TO_REF){
    uint8_t *mem_dut = (uint8_t *)buf;
    for(int i = 0; i < n; i++){
      paddr_write(addr + i, sizeof(uint8_t), *mem_dut++);
    }
  }else{
    assert(0);
  }
}

void diff_set_regs(void* diff_context){
  struct diff_context_t* ctx = (struct diff_context_t*)diff_context;
  for(int i = 0; i < RISCV_GPR_NUM; i++){
    cpu.gpr[i] = ctx->gpr[i];
  }
  cpu.pc = ctx->pc;
}

void diff_get_regs(void *diff_context){
  struct diff_context_t *ctx = (struct diff_context_t*)diff_context;
  for(int i = 0; i < RISCV_GPR_NUM; i++){
    ctx->gpr[i] = cpu.gpr[i];
  }
  ctx->pc = cpu.pc;
  ctx->mstatus = cpu.mstatus;
  ctx->mtvec = cpu.mtvec;
  ctx->mepc = cpu.mepc;
  ctx->mcause = cpu.mcause;
}

void diff_get_memtrace(void *diff_memtrace){
  struct diff_memtrace_t *memt = (struct diff_memtrace_t*)diff_memtrace;
  memt->data = diff_memtrace_ref.data;
  memt->address = diff_memtrace_ref.address;
  memt->length = diff_memtrace_ref.length;
  memt->is_write_mem = diff_memtrace_ref.is_write_mem;
}

__EXPORT void difftest_regcpy(void *dut, bool direction) {
  if(direction == DIFFTEST_TO_REF){
    diff_set_regs(dut);
  }else{
    diff_get_regs(dut);
  }
}

__EXPORT void difftest_memtrace_cpy(void *dut, bool direction) {
  if(direction == DIFFTEST_TO_DUT){
    diff_get_memtrace(dut);
  }else{
    assert(0);
  }
}

__EXPORT void difftest_exec(uint64_t n) {
  cpu_exec(n);
}

__EXPORT void difftest_raise_intr(word_t NO) {
  assert(0);
}

__EXPORT void difftest_init(int port) {
  void init_mem();
  init_mem();
  /* Perform ISA dependent initialization. */
  init_isa();
}
