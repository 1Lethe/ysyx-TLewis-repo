import "DPI-C" function void halt ();
`include "define/exu_command.v"

module ysyx_24120013_EXU #(ADDR_WIDTH = 5, DATA_WIDTH = 32)(
        input clk,
        input rst,

        input [DATA_WIDTH-1:0] alu_src1,
        input [DATA_WIDTH-1:0] alu_src2,
        input [ADDR_WIDTH-1:0] alu_des_addr,
        input [`ysyx_24120013_ALUOP_WIDTH-1:0] alu_op,

        input [DATA_WIDTH-1:0] branch_imm,
        input [DATA_WIDTH-1:0] branch_rs1,
        input [DATA_WIDTH-1:0] branch_pc,
        input [`ysyx_24120013_BRANCH_WIDTH-1:0] branch_op,

        input break_ctrl,

        output wire reg_wen,
        output wire [ADDR_WIDTH-1:0] reg_waddr,
        output wire [DATA_WIDTH-1:0] reg_wdata,
        output wire [DATA_WIDTH-1:0] branch_jmp_pc
    );

    assign reg_wen = (alu_des_addr == 0) ? 1'b0 : 1'b1;
    assign reg_waddr = (alu_des_addr == 0) ? {ADDR_WIDTH{1'b0}} : des_addr;
    assign reg_wdata = (alu_des_addr == 0) ? {DATA_WIDTH{1'b0}} : alu_result;

    always @(*) begin
        if(break_ctrl) halt();
    end

    reg [DATA_WIDTH-1:0] alu_result;

ysyx_24120013_alu #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
)u_ysyx_24120013_alu(
    .src1       	(alu_src1        ),
    .src2       	(alu_src2        ),
    .alu_op    	(alu_op         ),
    .alu_result 	(alu_result      )
);

// output declaration of module ysyx_24120013_branch_ctrl
ysyx_24120013_branch_ctrl #(
    .DATA_WIDTH(DATA_WIDTH)
)u_ysyx_24120013_branch_ctrl(
    .clk           	(clk            ),
    .rst           	(rst            ),
    .branch_less(1'b0),
    .branch_zero(1'b0),
    .branch_op     	(branch_op      ),
    .branch_imm    	(branch_imm     ),
    .branch_rs1    	(branch_rs1     ),
    .branch_pc     	(branch_pc      ),
    .branch_jmp_pc 	(branch_jmp_pc  )
);


endmodule