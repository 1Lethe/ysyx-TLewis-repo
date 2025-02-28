import "DPI-C" function void sim_pmem_write(input int waddr, input int wdata, input byte wmask);
import "DPI-C" function int sim_pmem_read(input int raddr);

import "DPI-C" function void halt ();

`include "define/exu_command.v"

module ysyx_24120013_top (
    input clk,
    input rst,
    output reg [DATA_WIDTH-1:0] pc,

    output wire [DATA_WIDTH-1:0] rf_dis [2**ADDR_WIDTH-1:0],
    output wire [DATA_WIDTH-1:0] trap_flag
);

parameter MEM_WIDTH = 32;
parameter ADDR_WIDTH = 5;
parameter DATA_WIDTH = 32;

wire pc_jmp_en;
wire [DATA_WIDTH-1:0] branch_jmp_pc;

ysyx_24120013_PC #(
    .DATA_WIDTH(DATA_WIDTH)
)u_ysyx_24120013_PC(
    .clk        	(clk          ),
    .rst        	(rst          ),
    .pc_jmp_val 	(branch_jmp_pc),
    .pc         	(pc           )
);

// output declaration of module ysyx_24120023_IFU
wire [31:0]inst;

ysyx_24120023_IFU u_ysyx_24120023_IFU(
    .clk      	(clk       ),
    .rst      	(rst       ),
    .pc         (pc        ),
    .IFU_inst 	(inst      )
);

// output declaration of module ysyx_24120013_IDU
wire [ADDR_WIDTH-1:0] reg_raddr1;
wire [ADDR_WIDTH-1:0] reg_raddr2;
wire [DATA_WIDTH-1:0] alu_src1;
wire [DATA_WIDTH-1:0] alu_src2;
wire [ADDR_WIDTH-1:0] wr_reg_des;
wire [`ysyx_24120013_ALUOP_WIDTH-1:0] alu_op;
wire [DATA_WIDTH-1:0] branch_imm;
wire [DATA_WIDTH-1:0] branch_rs1;
wire [DATA_WIDTH-1:0] branch_pc;
wire [`ysyx_24120013_BRANCH_WIDTH-1:0] branch_op;
wire mem_valid;
wire mem_ren;
wire mem_wen;
wire [DATA_WIDTH-1:0] mem_wdata;
wire [7:0] mem_wtype;
wire [7:0] mem_rtype;
wire [`ysyx_24120013_ZERO_WIDTH-1:0] mem_zero_width;
wire [`ysyx_24120013_SEXT_WIDTH-1:0] mem_sext_width;
wire break_ctrl;

ysyx_24120013_IDU #(
    .MEM_WIDTH  (MEM_WIDTH ),
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
)u_ysyx_24120013_IDU(
    .clk         	(clk          ),
    .rst         	(rst          ),
    .inst        	(inst         ),
    .pc             (pc           ),
    .reg_rdata1     (reg_rdata1   ),
    .reg_rdata2     (reg_rdata2   ),
    .reg_raddr1  	(reg_raddr1   ),
    .reg_raddr2  	(reg_raddr2   ),
    .alu_src1    	(alu_src1     ),
    .alu_src2    	(alu_src2     ),
    .alu_op         (alu_op       ),
    .branch_op      (branch_op    ),
    .branch_imm     (branch_imm   ),
    .branch_rs1     (branch_rs1   ),
    .branch_pc      (branch_pc    ),
    .mem_valid      (mem_valid    ),
    .mem_ren        (mem_ren      ),
    .mem_wen        (mem_wen      ),
    .mem_wdata      (mem_wdata    ),
    .mem_wtype      (mem_wtype    ),
    .mem_rtype      (mem_rtype    ),
    .mem_zero_width (mem_zero_width),
    .mem_sext_width (mem_sext_width),
    .wr_reg_des     (wr_reg_des   ),
    .break_ctrl     (break_ctrl   )
);

// output declaration of module ysyx_24120013_RegisterFile
wire [DATA_WIDTH-1:0] reg_rdata1;
wire [DATA_WIDTH-1:0] reg_rdata2;

ysyx_24120013_RegisterFile #(
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
)u_ysyx_24120013_RegisterFile(
    .clk    	(clk         ),
    .rst    	(rst         ),
    .wdata  	(reg_wdata   ),
    .waddr  	(reg_waddr   ),
    .wen    	(reg_wen     ),
    .raddr1 	(reg_raddr1  ),
    .raddr2 	(reg_raddr2  ),
    .rdata1 	(reg_rdata1  ),
    .rdata2 	(reg_rdata2  ),
    .rf_dis     (rf_dis      ),
    .trap_flag  (trap_flag   )
);

// output declaration of module ysyx_24120013_EXU
wire reg_wen;
wire [ADDR_WIDTH-1:0] reg_waddr;
wire [DATA_WIDTH-1:0] reg_wdata;

ysyx_24120013_EXU #(
    .MEM_WIDTH (MEM_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
)u_ysyx_24120013_EXU(
    .clk       	    (clk           ),
    .rst       	    (rst           ),
    .alu_src1      	(alu_src1      ),
    .alu_src2      	(alu_src2      ),
    .alu_op         (alu_op        ),
    .branch_imm     (branch_imm    ),
    .branch_rs1     (branch_rs1    ),
    .branch_pc      (branch_pc     ),
    .branch_op      (branch_op     ),
    .mem_valid      (mem_valid     ),
    .mem_ren        (mem_ren       ),
    .mem_wen        (mem_wen       ),
    .mem_wdata      (mem_wdata     ),
    .mem_wtype      (mem_wtype     ),
    .mem_rtype      (mem_rtype     ),
    .mem_zero_width (mem_zero_width),
    .mem_sext_width (mem_sext_width),
    .break_ctrl     (break_ctrl    ),
    .wr_reg_des     (wr_reg_des    ),
    .reg_wen   	    (reg_wen       ),
    .reg_waddr 	    (reg_waddr     ),
    .reg_wdata 	    (reg_wdata     ),
    .branch_jmp_pc  (branch_jmp_pc )
);

endmodule
