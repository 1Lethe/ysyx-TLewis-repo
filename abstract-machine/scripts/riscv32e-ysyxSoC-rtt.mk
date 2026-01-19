include $(AM_HOME)/scripts/isa/riscv.mk
include $(AM_HOME)/scripts/platform/ysyxSoC.mk
CFLAGS += -DISA_H=\"riscv/riscv.h\"
CFLAGS += -D_AM_TARGET_RTT
COMMON_CFLAGS += -march=rv32e_zicsr -mabi=ilp32e  # overwrite
LDFLAGS       += -melf32lriscv                    # overwrite
LDSCRIPTS += $(AM_HOME)/scripts/linker_ysyxSoC_rtt.ld

AM_SRCS += riscv/ysyxSoC/libgcc/div.S \
           riscv/ysyxSoC/libgcc/muldi3.S \
           riscv/ysyxSoC/libgcc/multi3.c \
           riscv/ysyxSoC/libgcc/ashldi3.c \
           riscv/ysyxSoC/libgcc/unused.c