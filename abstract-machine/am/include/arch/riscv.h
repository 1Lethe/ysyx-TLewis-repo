#ifndef ARCH_H__
#define ARCH_H__

#ifdef __riscv_e
#define NR_REGS 16
#else
#define NR_REGS 32
#endif

struct Context {
  // TODO: fix the order of these members to match trap.S
  void *pdir;
  uintptr_t gpr[NR_REGS - 1];
  uintptr_t mcause;
  uintptr_t mstatus;
  uintptr_t mepc;
};

#ifdef __riscv_e
#define GPR1 gpr[15 - 1] // a5
#else
#define GPR1 gpr[17 - 1] // a7 system call
#endif

#define GPR2 gpr[10 - 1] // a0 arg1 
#define GPR3 gpr[11 - 1] // a1 arg2 | ret val 2
#define GPR4 gpr[12 - 1] // a2 arg3
#define GPRx gpr[10 - 1] // a0 ret val 1

#endif
