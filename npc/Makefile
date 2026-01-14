# ==============================================================================
# 0. 伪目标定义 (Phony Targets)
# ==============================================================================
.PHONY: default sim nvboard run clean count count_noempty
.PHONY: syn fix-fanout sta clean_sta

default: sim

# ==============================================================================
# 1. 全局配置与工具 (Global Config & Tools)
# ==============================================================================
TOPNAME   = ysyxSoCFull
BUILD_DIR = $(NPC_HOME)/build
OBJ_DIR   = $(BUILD_DIR)/obj_dir
WAVE_DIR  = $(NPC_HOME)/wave

BIN_SIM     = $(BUILD_DIR)/$(TOPNAME)
BIN_NVBOARD = $(BUILD_DIR)/$(TOPNAME)

VERILATOR = verilator
NPROC     = $(shell nproc)

# ==============================================================================
# 2. 路径定义 (Path Definitions)
# ==============================================================================

# [Type A] Verilog Include Paths (供 Verilator 解析 .v 使用)
V_INC_DIRS = ./vsrc \
             ./vsrc/define \
             $(YSYX_HOME)/ysyxSoC/perip/uart16550/rtl \
             $(YSYX_HOME)/ysyxSoC/perip/spi/rtl

V_INC_FLAGS = $(addprefix -I, $(V_INC_DIRS))

# [Type B] C/C++ Include Paths (供 GCC 编译 .cpp 使用)
C_INC_DIRS = $(NPC_HOME)/csrc/include \
             $(NPC_HOME)/capstone/repo/include

C_INC_FLAGS = $(addprefix -I, $(C_INC_DIRS))

CAPSTONE_SO_PATH = $(abspath $(NPC_HOME)/capstone/repo/libcapstone.so.5)
WAVE_FILE_PATH = $(abspath $(WAVE_DIR)/wave.fst)

# ==============================================================================
# 3. 源文件管理 (Source Management)
# ==============================================================================

# 3.1 Verilog 源文件
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v") \
        $(shell find $(abspath $(YSYX_HOME)/ysyxSoC/perip) -name "*.v") \
        $(YSYX_HOME)/ysyxSoC/build/ysyxSoCFull.v

# 3.2 外部依赖 (Filelist)
include $(NPC_HOME)/csrc/utils/filelist.mk

# YSYX-workbench依赖
include ../Makefile

# 3.3 C++ 源文件分类
# 自动生成的绑定文件
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)

# [SIM] 纯仿真用的 C++ (排除 NVBoard 相关)
CSRCS_SIM = $(shell find $(abspath ./csrc) \( -name "*.c" -or -name "*.cc" -or -name "*.cpp" \) ! -name "nvboard.cpp")

# [NVBOARD] UI 仿真用的 C++ (排除纯仿真主函数, 包含自动绑定)
CSRCS_NVBOARD = $(shell find $(abspath ./csrc) \( -name "*.c" -or -name "*.cc" -or -name "*.cpp" \) ! -name "sim_main.cpp")
CSRCS_NVBOARD += $(SRC_AUTO_BIND)

# ==============================================================================
# 4. 编译参数配置 (Compilation Flags)
# ==============================================================================

# 4.1 GCC 基础参数 (CFLAGS)
# 注意：C_INC_FLAGS 只能放在这里
COMMON_CFLAGS  = -O3 -march=native -MMD
COMMON_CFLAGS += -DTOP_NAME="\"V$(TOPNAME)\""
COMMON_CFLAGS += $(C_INC_FLAGS)
COMMON_CFLAGS += -DCAPSTONE_SO_PATH=$(CAPSTONE_SO_PATH)
COMMON_CFLAGS += -DWAVE_OUTPUT_FILE=$(WAVE_FILE_PATH)

# 4.2 链接器参数 (LDFLAGS)
COMMON_LDFLAGS = -lreadline -ldl -fuse-ld=lld

# 4.3 Verilator 核心参数
# 注意：V_INC_FLAGS 只能放在这里
VERILATOR_FLAGS = --cc --exe --build \
                  --no-assert --no-timing --timescale "1ns/1ns" \
				  --trace-fst \
                  --x-assign fast --x-initial fast \
                  -j $(NPROC) \
                  --threads 1 --threads-dpi all --instr-count-dpi 1 \
                  $(V_INC_FLAGS)

# ==============================================================================
# 5. 构建规则 (Build Rules)
# ==============================================================================

# 确保构建目录存在
$(shell mkdir -p $(BUILD_DIR))

# --- 规则 A: 生成 Auto Bind 文件 (NVBoard 依赖) ---
NXDC_FILES = constr/top.nxdc
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# --- 规则 B: 纯仿真 (Sim Target) ---
sim: $(VSRCS) $(CSRCS_SIM)
	@rm -f $(WAVE_DIR)/*.fst
	$(call git_commit, "sim RTL")
	@echo "Building Simulation Binary (SIM)..."
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module $(TOPNAME) $^ \
		-CFLAGS "$(COMMON_CFLAGS)" \
		-LDFLAGS "$(COMMON_LDFLAGS)" \
		--Mdir $(OBJ_DIR) -o $(abspath $(BIN_SIM))
	@echo "Sim Build Complete. Run: $(BIN_SIM)"

# --- 规则 C: NVBoard 仿真 (NVBoard Target) ---
# 引入 NVBoard 标准脚本
include $(NVBOARD_HOME)/scripts/nvboard.mk

nvboard: $(VSRCS) $(CSRCS_NVBOARD) $(NVBOARD_ARCHIVE)
	$(call git_commit, "NVBoard RTL")
	@echo "Building NVBoard Binary (UI)..."
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--top-module $(TOPNAME) $^ \
		-CFLAGS "$(COMMON_CFLAGS) $(NVBOARD_CFLAGS)" \
		-LDFLAGS "$(COMMON_LDFLAGS) $(NVBOARD_LDFLAGS)" \
		--Mdir $(OBJ_DIR) -o $(abspath $(BIN_NVBOARD))
	@echo "NVBoard Build Complete. Run: $(BIN_NVBOARD)"

# --- 规则 D: 运行 NVBoard ---
run: nvboard
	@echo "Running NVBoard..."
	$(BIN_NVBOARD)

# ==============================================================================
# 6. 辅助工具规则 (Utils)
# ==============================================================================

clean:
	rm -rf $(BUILD_DIR)
	rm -f $(WAVE_DIR)/*.fst
	@echo "Clean build and wave complete."

C_FILES_FIND_CMD = find ./csrc -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.cc" -o -name "*.h" \)

# 统计总行数 (Physical Lines of Code)
count:
	@echo "========================================"
	@echo " [Verilog] RTL Logic Lines:"
	@find $(NPC_HOME) -name "*.v" | xargs wc -l | grep "total" || echo "No Verilog files found."
	@echo "----------------------------------------"
	@echo " [C/C++] Simulation/Testbench Lines:"
	@$(C_FILES_FIND_CMD) | xargs wc -l | grep "total" || echo "No C/C++ files found."
	@echo "========================================"

# 统计非空行数 (Source Lines of Code - SLOC)
# 排除纯空行和仅包含空白字符的行
count_noempty:
	@echo "========================================"
	@echo " [Verilog] RTL Non-Empty Lines:"
	@find $(NPC_HOME) -name "*.v" | xargs grep -v "^\s*$$" | wc -l || echo "0"
	@echo "----------------------------------------"
	@echo " [C/C++] Simulation/Testbench Non-Empty Lines:"
	@$(C_FILES_FIND_CMD) | xargs grep -v "^\s*$$" | wc -l || echo "0"
	@echo "========================================"

# ==============================================================================
# 7. 综合与时序分析 (Synthesis & STA) 
# ==============================================================================

# For sta
PROJ_PATH = $(NPC_HOME)

DESIGN ?= ysyx_24120013
SDC_FILE ?= $(PROJ_PATH)/sdc/top.sdc
RTL_FILES ?= $(shell find $(abspath ./vsrc) -name "*.v")
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

clean_sta:
	rm -rf $(PROJ_PATH)/sta_result