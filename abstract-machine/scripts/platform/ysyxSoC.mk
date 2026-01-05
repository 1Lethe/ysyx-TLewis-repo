AM_SRCS := riscv/ysyxSoC/start.S \
           riscv/ysyxSoC/trm.c \
           riscv/ysyxSoC/ioe.c \
           riscv/ysyxSoC/timer.c \
           riscv/ysyxSoC/input.c \
           riscv/ysyxSoC/cte.c \
           riscv/ysyxSoC/trap.S \
           platform/dummy/vme.c \
           platform/dummy/mpe.c

CFLAGS    += -fdata-sections -ffunction-sections
CFLAGS    += -I$(AM_HOME)/am/src/riscv/ysyxSoC/include
LDSCRIPTS += $(AM_HOME)/scripts/linker_ysyxSoC.ld
LDFLAGS   += --defsym=_sram_start=0x0f000000 --defsym=_sram_end=0x0f002000 --defsym=_entry_offset=0x0
LDFLAGS   += --defsym=_mrom_start=0x20000000
LDFLAGS   += --defsym=_heap_size=0x200
LDFLAGS   += --gc-sections -e _start
NPCFLAGS  += --elf=$(IMAGE).elf --diff=$(NEMU_HOME)/build/riscv32-nemu-interpreter-so --port=1234 -l $(shell dirname $(IMAGE).elf)/NPC-log.txt $(IMAGE).bin

MAINARGS_MAX_LEN = 64
MAINARGS_PLACEHOLDER = The insert-arg rule in Makefile will insert mainargs here.
CFLAGS += -DMAINARGS_MAX_LEN=$(MAINARGS_MAX_LEN) -DMAINARGS_PLACEHOLDER=\""$(MAINARGS_PLACEHOLDER)"\"

insert-arg: image
	@python $(AM_HOME)/tools/insert-arg.py $(IMAGE).bin $(MAINARGS_MAX_LEN) "$(MAINARGS_PLACEHOLDER)" "$(mainargs)"

image: image-dep
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

run: insert-arg
	$(MAKE) -C $(NPC_HOME) ISA=$(ISA) sim IMG=$(IMAGE).bin
	$(NPC_HOME)/build/ysyxSoCFull $(NPCFLAGS)

.PHONY: insert-arg
