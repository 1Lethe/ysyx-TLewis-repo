.PHONY = all run sim clean clean_wave clean_all syn fix-fanout sta clean_sta

TOPNAME = ysyx_24120013_top
NXDC_FILES = constr/top.nxdc
INC_PATH ?=

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

default: $(BIN)

$(shell mkdir -p $(BUILD_DIR))

# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# project source
VSRCS = $(shell find $(abspath ./vsrc) \( -name "*.v" -or -name "*.sv" \))
CSRCS = $(shell find $(abspath ./csrc) \( -name "*.c" -or -name "*.cc" -or -name "*.cpp" \) ! -name "sim_main.cpp" )
CSRCS += $(SRC_AUTO_BIND)

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

#For sim
SIM_TOPNAME = ysyx_24120013_top
VER_SIM_V_PATH = $(VSRCS)
VER_SIM_C_PATH = $(shell find $(abspath ./csrc) \( -name "*.c" -or -name "*.cc" -or -name "*.cpp" \) ! -name "nvboard.cpp" )
VER_SIM_CFLAGS = -cc --exe -trace-fst --build
sim:$(VER_SIM_V_PATH) $(VER_SIM_C_PATH)
	rm -rf $(WAVE_DIR)
	mkdir ./wave
	$(call git_commit, "sim RTL")
	verilator -cc --exe --trace-fst --build --timing --top-module $(SIM_TOPNAME) $^ \
	--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))
	./build/$(SIM_TOPNAME)
	@echo "Sim Complete."


# For sta
PROJ_PATH = $(NPC_HOME)

DESIGN ?= top
SDC_FILE ?= $(PROJ_PATH)/sdc/top.sdc
RTL_FILES ?= $(VSRCS)
export CLK_FREQ_MHZ ?= 100

RESULT_DIR = $(PROJ_PATH)/sta_result/$(DESIGN)-$(CLK_FREQ_MHZ)MHz
SCRIPT_DIR = $(PROJ_PATH)/scripts
NETLIST_SYN_V   = $(RESULT_DIR)/$(DESIGN).netlist.syn.v
NETLIST_FIXED_V = $(RESULT_DIR)/$(DESIGN).netlist.fixed.v
TIMING_RPT = $(RESULT_DIR)/$(DESIGN).rpt

syn: $(NETLIST_SYN_V)
$(NETLIST_SYN_V): $(RTL_FILES) $(SCRIPT_DIR)/yosys.tcl
	mkdir -p $(@D)
	echo tcl $(SCRIPT_DIR)/yosys.tcl $(DESIGN) \"$(RTL_FILES)\" $@ | yosys -l $(@D)/yosys.log -s -

fix-fanout: $(NETLIST_FIXED_V)
$(NETLIST_FIXED_V): $(SCRIPT_DIR)/fix-fanout.tcl $(SDC_FILE) $(NETLIST_SYN_V)
	./bin/iEDA -script $^ $(DESIGN) $@ 2>&1 | tee $(RESULT_DIR)/fix-fanout.log

sta: $(TIMING_RPT)
$(TIMING_RPT): $(SCRIPT_DIR)/sta.tcl $(SDC_FILE) $(NETLIST_FIXED_V)
	./bin/iEDA -script $^ $(DESIGN) 2>&1 | tee $(RESULT_DIR)/sta.log

# For NVBoard
run: $(BIN)
	@echo "Link in NVBoard."
	@$^

WAVE_DIR = wave
STA_DIR = $(PROJ_PATH)/sta_result
clean: 
	rm -rf $(BUILD_DIR)
	rm -rf $(STA_DIR)/*
	rm -rf $(WAVE_DIR)/*
	@echo "Clean all complete."

include ../Makefile