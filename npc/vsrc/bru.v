`include "define/exu_command.v"

module ysyx_24120013_bru #(DATA_WIDTH = 32)(
    input clk,
    input rst,
    input branch_less,
    input branch_zero,
    input [`ysyx_24120013_BRANCH_WIDTH-1:0] branch_op,
    input [DATA_WIDTH-1:0] branch_imm,
    input [DATA_WIDTH-1:0] branch_rs1,
    input [DATA_WIDTH-1:0] branch_pc,
    output wire [DATA_WIDTH-1:0] branch_jmp_pc 
);

    wire is_jmp;

    wire [DATA_WIDTH-1:0] branch_src1;
    wire [DATA_WIDTH-1:0] branch_src2;

    assign is_jmp = (branch_op[0] == 1'b1) ||
                    (branch_op[1] == 1'b1);

    assign branch_src1 = (is_jmp == 1'b1) ? branch_imm : 4;
    assign branch_src2 = (branch_op[1] == 1'b1) ? branch_rs1 : branch_pc;

    assign branch_jmp_pc = branch_src1 + branch_src2;

endmodule