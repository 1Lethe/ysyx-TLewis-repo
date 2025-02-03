`include "define/exu_command.v"

module ysyx_24120013_top (
    input clk,
    input rst,
    input [31:0] pmem,
    output reg [31:0] pc
);

parameter ADDR_WIDTH = 5;
parameter DATA_WIDTH = 32;

wire pc_jmp_en;
wire [DATA_WIDTH-1:0] pc_jmp_val;

ysyx_24120013_PC #(
    .DATA_WIDTH(DATA_WIDTH)
)u_ysyx_24120013_PC(
    .clk        	(clk         ),
    .rst        	(rst         ),
    .pc_jmp_en  	(pc_jmp_en),
    .pc_jmp_val 	(pc_jmp_val),
    .pc         	(pc          )
);

// output declaration of module ysyx_24120023_IFU
wire [31:0]inst;

ysyx_24120023_IFU u_ysyx_24120023_IFU(
    .clk      	(clk       ),
    .rst      	(rst       ),
    .inst     	(pmem      ),
    .IFU_inst 	(inst  )
);

// output declaration of module ysyx_24120013_IDU
wire [ADDR_WIDTH-1:0] reg_raddr1;
wire [ADDR_WIDTH-1:0] reg_raddr2;
wire [DATA_WIDTH-1:0] alu_src1;
wire [DATA_WIDTH-1:0] alu_src2;
wire [ADDR_WIDTH-1:0] alu_des;
wire [`ysyx_24120013_ALUOP_WIDTH-1:0] alu_op;
wire break_ctrl;

ysyx_24120013_IDU #(
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
)u_ysyx_24120013_IDU(
    .clk         	(clk          ),
    .rst         	(rst          ),
    .inst        	(inst     ),
    .pc             (pc           ),
    .reg_rdata1      	(reg_rdata1       ),
    .reg_rdata2      	(reg_rdata2       ),
    .reg_raddr1  	(reg_raddr1   ),
    .reg_raddr2  	(reg_raddr2   ),
    .alu_src1    	(alu_src1     ),
    .alu_src2    	(alu_src2     ),
    .alu_des     	(alu_des      ),
    .alu_op 	(alu_op  ),
    .break_ctrl (break_ctrl)
);

// output declaration of module ysyx_24120013_RegisterFile
wire [DATA_WIDTH-1:0] reg_rdata1;
wire [DATA_WIDTH-1:0] reg_rdata2;

ysyx_24120013_RegisterFile #(
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
)u_ysyx_24120013_RegisterFile(
    .clk    	(clk     ),
    .rst    	(rst     ),
    .wdata  	(reg_wdata   ),
    .waddr  	(reg_waddr   ),
    .wen    	(reg_wen     ),
    .raddr1 	(reg_raddr1  ),
    .raddr2 	(reg_raddr2  ),
    .rdata1 	(reg_rdata1  ),
    .rdata2 	(reg_rdata2  )
);

// output declaration of module ysyx_24120013_EXU
wire reg_wen;
wire [ADDR_WIDTH-1:0] reg_waddr;
wire [DATA_WIDTH-1:0] reg_wdata;

ysyx_24120013_EXU #(
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
)u_ysyx_24120013_EXU(
    .clk       	(clk        ),
    .rst       	(rst        ),
    .src1      	(alu_src1   ),
    .src2      	(alu_src2   ),
    .des_addr   (alu_des    ),
    .break_ctrl (break_ctrl),
    .alu_op     (alu_op),
    .reg_wen   	(reg_wen    ),
    .reg_waddr 	(reg_waddr  ),
    .reg_wdata 	(reg_wdata  ),
    .pc_jump_en (pc_jmp_en),
    .pc_jump_val (pc_jmp_val)
);

endmodule
