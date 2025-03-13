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

    input ecu_jump_pc_flag,
    input [DATA_WIDTH-1:0] ecu_jump_pc,

    output wire [DATA_WIDTH-1:0] branch_jmp_pc 
);

    wire op_jal;
    wire op_jalr;
    wire op_beq;
    wire op_bne;
    wire op_blt;
    wire op_bltu;
    wire op_bge;
    wire op_bgeu;

    wire is_jmp;

    wire is_nocon_jmp;
    wire is_eq_jmp;
    wire is_neq_jmp;
    wire is_lt_jmp;
    wire is_ltu_jmp;
    wire is_ge_jmp;
    wire is_geu_jmp;

    wire [DATA_WIDTH-1:0] branch_src1;
    wire [DATA_WIDTH-1:0] branch_src2;

    assign op_jal  = branch_op[0];
    assign op_jalr = branch_op[1];
    assign op_beq  = branch_op[2];
    assign op_bne  = branch_op[3];
    assign op_blt  = branch_op[4];
    assign op_bltu = branch_op[5];
    assign op_bge  = branch_op[6];
    assign op_bgeu = branch_op[7];

    assign is_nocon_jmp = (op_jal  | op_jalr     );
    assign is_eq_jmp    = (op_beq  & branch_zero );
    assign is_neq_jmp   = (op_bne  & ~branch_zero);
    assign is_lt_jmp    = (op_blt  & branch_less );
    assign is_ltu_jmp   = (op_bltu & branch_less );
    assign is_ge_jmp    = (op_bge  & ~branch_less);
    assign is_geu_jmp   = (op_bgeu & ~branch_less);

    assign is_jmp = is_nocon_jmp | is_eq_jmp | is_neq_jmp | is_lt_jmp | is_ltu_jmp | is_ge_jmp | is_geu_jmp;

    assign branch_src1 = (is_jmp == 1'b1) ? branch_imm : 4;
    assign branch_src2 = (op_jalr == 1'b1) ? branch_rs1 : branch_pc;

    assign branch_jmp_pc =  (ecu_jump_pc_flag == 1'b1) ? ecu_jump_pc : 
                            (op_jalr == 1'b1) ? (branch_src1 + branch_src2) & (~32'b1) : 
                                               branch_src1 + branch_src2;

endmodule