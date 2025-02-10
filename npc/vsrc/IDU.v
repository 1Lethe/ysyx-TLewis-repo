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

        output wire [`ysyx_24120013_BRANCH_WIDTH-1:0] branch_op,
        output wire [DATA_WIDTH-1:0] branch_imm,
        output wire [DATA_WIDTH-1:0] branch_rs1,
        output wire [DATA_WIDTH-1:0] branch_pc,

        output wire break_ctrl
    );

    /* Decoder opcode parameter */
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

    /* extract parts of the inst signal */
    wire [6:0] opcode;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;
    wire [2:0] funct3;
    wire [6:0] funct7;

    /* inst decoder signal */

    wire opcode_is_imm;
    wire opcode_is_calc;
    wire opcode_is_lui;
    wire opcode_is_auipc;
    wire opcode_is_jal;
    wire opcode_is_jalr;
    wire opcode_is_branch;
    wire opcode_is_load;
    wire opcode_is_save;
    wire opcode_is_break;

    wire [7:0] funct3_one_hot;

    wire is_addi;
    wire is_slti;
    wire is_sltiu;
    wire is_andi;
    wire is_ori;
    wire is_xori;
    wire is_slli;
    wire is_srli;
    wire is_srai;
    wire is_lui;
    wire is_auipc;

    wire is_add;
    wire is_sub;
    wire is_slt;
    wire is_sltu;
    wire is_and;
    wire is_or;
    wire is_xor;
    wire is_sll;
    wire is_srl;
    wire is_sra;

    wire is_jal;
    wire is_jalr;

    wire is_ebreak;

    /* immediate number calc signal */
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

    /* alu src control signal */
    wire alu_src1_pc;
    wire alu_src2_imm;
    wire alu_src2_plus4; 
    wire alu_nwr_reg;

    assign opcode = inst[6:0];
    assign rs1 = inst[19:15];
    assign rs2 = inst[24:20];
    assign rd = inst[11:7];
    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];

    assign opcode_is_imm    = (opcode == OPC_IMM_C);
    assign opcode_is_calc   = (opcode == OPC_CALC);
    assign opcode_is_lui    = (opcode == OPC_LUI);
    assign opcode_is_auipc  = (opcode == OPC_AUIPC);
    assign opcode_is_jal    = (opcode == OPC_JAL);
    assign opcode_is_jalr   = (opcode == OPC_JALR);
    assign opcode_is_branch = (opcode == OPC_BRANCH);
    assign opcode_is_load   = (opcode == OPC_LOAD);
    assign opcode_is_save   = (opcode == OPC_SAVE);
    assign opcode_is_break  = (opcode == OPC_BREAK);

    assign funct3_one_hot = 1'b1 << funct3;

    assign is_addi   = (opcode_is_imm)    & (funct3_one_hot[0]);
    assign is_lui    = (opcode_is_lui);
    assign is_auipc  = (opcode_is_auipc);
    assign is_add    = (opcode_is_calc)   & (funct3_one_hot[0]);
    assign is_jal    = (opcode_is_jal);
    assign is_jalr   = (opcode_is_jalr)   & (funct3_one_hot[0]);
    assign is_ebreak = (opcode_is_break);

    assign alu_op[0]  = is_addi | // add
                        is_add  |
                        is_auipc|
                        is_jal  |
                        is_jalr;
    assign alu_op[1]  = is_sub;   // sub
    assign alu_op[2]  = is_slti;  // less than
    assign alu_op[3]  = is_sltiu; // less than unsigned
    assign alu_op[4]  = is_andi;  // and
    assign alu_op[5]  = is_ori;   // or
    assign alu_op[6]  = is_xor;   // xor
    assign alu_op[7]  = is_slli;  // logical left shift
    assign alu_op[8]  = is_srli;  // logical right shift
    assign alu_op[9]  = is_srai;  // arithmetic right shift
    assign alu_op[10] = is_lui;   // select B src

    assign branch_op[0] = is_jal;
    assign branch_op[1] = is_jalr;

    assign branch_imm = (branch_op != 0) ? imm : 0;
    assign branch_rs1 = (branch_op != 0) ? reg_rdata1 : 0;
    assign branch_pc  = pc; 

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

    assign alu_src1_pc  = (opcode == OPC_AUIPC)  ||
                          (opcode == OPC_JAL)    ||
                          (opcode == OPC_BRANCH);

    assign alu_src2_imm = (opcode == OPC_IMM_C)  ||
                          (opcode == OPC_LUI)    ||
                          (opcode == OPC_AUIPC)  ||
                          (opcode == OPC_BRANCH) ||
                          (opcode == OPC_LOAD)   ||
                          (opcode == OPC_SAVE);

    assign alu_src2_plus4 = (opcode == OPC_JAL) ||
                            (opcode == OPC_JALR);

    assign alu_nwr_reg = (opcode == OPC_BRANCH) ||
                         (opcode == OPC_SAVE)   ||
                         (opcode == OPC_BREAK);
    
    assign reg_raddr1 = (alu_src1_pc == 1'b1) ? {ADDR_WIDTH{1'b0}} : rs1;
    assign reg_raddr2 = (alu_src2_imm == 1'b1) ? {ADDR_WIDTH{1'b0}} : rs2;
    assign alu_src1 = (alu_src1_pc == 1'b1) ? pc : reg_rdata1;
    assign alu_src2 = (alu_src2_imm == 1'b1) ? imm : 
                      (alu_src2_plus4 == 1'b1) ? 4 : reg_rdata2;
    assign alu_des = (alu_nwr_reg == 1'b1) ? {ADDR_WIDTH{1'b0}} : rd;

endmodule
