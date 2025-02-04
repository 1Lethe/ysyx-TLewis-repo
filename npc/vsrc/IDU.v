`include "define/exu_command.v"

module ysyx_24120013_IDU #(ADDR_WIDTH = 5, DATA_WIDTH = 32)(
        input clk,
        input rst,
        input [DATA_WIDTH-1:0] inst,
        input [DATA_WIDTH-1:0] pc,
        input [DATA_WIDTH-1:0] reg_rdata1,
        input [DATA_WIDTH-1:0] reg_rdata2,
        output wire [ADDR_WIDTH-1:0] reg_raddr1,
        output wire [ADDR_WIDTH-1:0] reg_raddr2,

        output wire [DATA_WIDTH-1:0] alu_src1,
        output wire [DATA_WIDTH-1:0] alu_src2,
        output wire [ADDR_WIDTH-1:0] alu_des,
        output wire [`ysyx_24120013_ALUOP_WIDTH-1:0] alu_op,
        output wire break_ctrl
    );

    parameter OPC_IMM_C  = 7'b0010011; // immediate calc
    parameter OPC_CALC   = 7'b0110011;
    parameter OPC_LUI    = 7'b0110111;
    parameter OPC_AUIPC  = 7'b0010111;
    parameter OPC_JAL    = 7'b1101111;
    parameter OPC_JALR   = 7'b1100111;
    parameter OPC_BRANCH = 7'b1100011;
    parameter OPC_LOAD   = 7'b0000011;
    parameter OPC_SAVE   = 7'b0100011;
    parameter OPC_BREAK  = 7'b1110011; //ebreak

    wire [6:0] opcode;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;
    wire [2:0] funct3;
    wire [6:0] funct7;

    wire is_addi;

    wire is_lui;
    wire is_auipc;

    wire is_ebreak;

    wire [DATA_WIDTH-1:0] imm_i;
    wire [DATA_WIDTH-1:0] imm_s;
    wire [DATA_WIDTH-1:0] imm_b;
    wire [DATA_WIDTH-1:0] imm_u;
    wire [DATA_WIDTH-1:0] imm_j;
    wire is_imm_i;
    wire is_imm_s;
    wire is_imm_b;
    wire is_imm_u;
    wire is_imm_j;
    wire [DATA_WIDTH-1:0]imm;

    wire src1_pc;
    wire src2_imm;
    wire src2_pc;
    wire rd_pc;

    assign opcode = inst[6:0];
    assign rs1 = inst[19:15];
    assign rs2 = inst[24:20];
    assign rd = inst[11:7];
    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];

    assign is_addi = (opcode == OPC_IMM_C) && (funct3 == 3'b000);
    assign is_lui = (opcode == OPC_LUI);
    assign is_auipc = (opcode == OPC_AUIPC);
    assign is_ebreak = (opcode == OPC_BREAK);

    assign alu_op[0] = is_addi |
                       is_auipc;
    assign alu_op[10] = is_lui;

    assign break_ctrl = (is_ebreak == 1'b1) ? 1'b1 : 1'b0;

    assign imm_i = {{20{inst[31]}}, inst[31:20]};
    assign imm_s = {{20{inst[31]}}, inst[31:25], inst[11:7]};
    assign imm_b = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    assign imm_u = {inst[31:12], 12'b0};
    assign imm_j = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

    assign is_imm_i = (opcode == OPC_IMM_C) || (opcode == OPC_JALR) || (opcode == OPC_LOAD);
    assign is_imm_s = (opcode == OPC_SAVE);
    assign is_imm_b = (opcode == OPC_BRANCH);
    assign is_imm_u = (opcode == OPC_LUI) || (opcode == OPC_AUIPC);
    assign is_imm_j = (opcode == OPC_JAL);

    assign imm = ({DATA_WIDTH{is_imm_i}} & imm_i) |
                 ({DATA_WIDTH{is_imm_s}} & imm_s) |
                 ({DATA_WIDTH{is_imm_b}} & imm_b) |
                 ({DATA_WIDTH{is_imm_u}} & imm_u) |
                 ({DATA_WIDTH{is_imm_j}} & imm_j);

    assign src1_pc  = (opcode == OPC_AUIPC)  ||
                      (opcode == OPC_JAL)    ||
                      (opcode == OPC_BRANCH);

    assign src2_imm = (opcode == OPC_IMM_C)  ||
           (opcode == OPC_LUI)    ||
           (opcode == OPC_AUIPC)  ||
           (opcode == OPC_JAL)    ||
           (opcode == OPC_JALR)   ||
           (opcode == OPC_BRANCH) ||
           (opcode == OPC_LOAD)   ||
           (opcode == OPC_SAVE);

    assign rd_pc = (opcode == OPC_JAL)  ||
                   (opcode == OPC_JALR) ||
                   (opcode == OPC_BRANCH);

    assign reg_raddr1 = (src1_pc == 1'b1) ? {ADDR_WIDTH{1'b0}} : rs1;
    assign reg_raddr2 = (src2_imm == 1'b1) ? {ADDR_WIDTH{1'b0}} : rs2;
    assign alu_src1 = (src1_pc == 1'b1) ? pc : reg_rdata1;
    assign alu_src2 = (src2_imm == 1'b1) ? imm : reg_rdata2;
    assign alu_des = (rd_pc == 1'b1) ? {ADDR_WIDTH{1'b0}} : rd;

endmodule
