module ysyx_24120013_IDU #(MEM_WIDTH = 32, ADDR_WIDTH = 5, DATA_WIDTH = 32)(
        input clk,
        input rst,
        input [DATA_WIDTH-1:0] inst,
        input [DATA_WIDTH-1:0] pc,
        input [DATA_WIDTH-1:0] reg_rdata1,
        input [DATA_WIDTH-1:0] reg_rdata2,

        input [DATA_WIDTH-1:0] csr_rdata,

        output wire [ADDR_WIDTH-1:0] reg_raddr1,
        output wire [ADDR_WIDTH-1:0] reg_raddr2,

        output wire [`ysyx_24120013_ECU_WIDTH-1:0] ecu_op,
        output wire [DATA_WIDTH-1:0] ecu_pc,
        output wire [DATA_WIDTH-1:0] ecu_reg_rdata,
        output wire [`ysyx_24120013_CSR_ADDR_WIDTH-1:0] csr_raddr,
        output wire [`ysyx_24120013_CSR_ADDR_WIDTH-1:0] ecu_csr_waddr,

        output wire [DATA_WIDTH-1:0] alu_src1,
        output wire [DATA_WIDTH-1:0] alu_src2,
        output wire [`ysyx_24120013_ALUOP_WIDTH-1:0] alu_op,

        output wire [`ysyx_24120013_BRANCH_WIDTH-1:0] branch_op,
        output wire [DATA_WIDTH-1:0] branch_imm,
        output wire [DATA_WIDTH-1:0] branch_rs1,
        output wire [DATA_WIDTH-1:0] branch_pc,

        output wire mem_valid,
        output wire mem_ren,
        output wire mem_wen,
        output wire [DATA_WIDTH-1:0] mem_wdata,
        output wire [7:0] mem_wtype,
        output wire [7:0] mem_rtype,
        output wire [`ysyx_24120013_ZERO_WIDTH-1:0] mem_zero_width,
        output wire [`ysyx_24120013_SEXT_WIDTH-1:0] mem_sext_width,

        output wire [ADDR_WIDTH-1:0] wr_reg_des,

        output wire break_ctrl,

        // shakehand signal
        input inst_is_valid,
        output wire id_is_ready,

        input ex_is_ready, 
        output wire id_is_valid
    );

    /* Shake hand signal */
    assign id_is_ready = ~rst ;
    assign id_is_valid = inst_is_valid;

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
    parameter OPC_CSR    = 7'b1110011; 

    /* extract parts of the inst signal */
    wire [6:0] opcode;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;
    wire [2:0] funct3;
    wire [6:0] funct7;

    wire [11:0] csr;

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
    wire opcode_is_csr;

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

    wire is_beq;
    wire is_bne;
    wire is_blt;
    wire is_bltu;
    wire is_bge;
    wire is_bgeu;

    wire is_lw;
    wire is_lh;
    wire is_lhu;
    wire is_lb;
    wire is_lbu;
    wire is_sw;
    wire is_sh;
    wire is_sb;

    wire is_ebreak;
    wire is_ecall;

    wire is_csrrw;
    wire is_csrrs;
    wire is_mret;

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
    wire alu_src1_reg;
    wire bru_src1_reg;
    wire ecu_src1_reg;
    wire alu_src1_pc;
    wire alu_src2_reg;
    wire mmu_src2_reg;
    wire alu_src2_imm;
    wire alu_src2_plus4;
    wire alu_src2_csr;
    wire not_wr_reg;

    assign opcode = inst[6:0];
    assign rs1 = inst[19:15];
    assign rs2 = inst[24:20];
    assign rd = inst[11:7];
    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];
    assign csr = inst[31:20];

    assign opcode_is_imm    = (opcode == OPC_IMM_C);
    assign opcode_is_calc   = (opcode == OPC_CALC);
    assign opcode_is_lui    = (opcode == OPC_LUI);
    assign opcode_is_auipc  = (opcode == OPC_AUIPC);
    assign opcode_is_jal    = (opcode == OPC_JAL);
    assign opcode_is_jalr   = (opcode == OPC_JALR);
    assign opcode_is_branch = (opcode == OPC_BRANCH);
    assign opcode_is_load   = (opcode == OPC_LOAD);
    assign opcode_is_save   = (opcode == OPC_SAVE);
    assign opcode_is_csr    = (opcode == OPC_CSR);

    assign funct3_one_hot = 1'b1 << funct3;

    assign is_addi   = (opcode_is_imm)    & (funct3_one_hot[0]);
    assign is_slti   = (opcode_is_imm)    & (funct3_one_hot[2]);
    assign is_sltiu  = (opcode_is_imm)    & (funct3_one_hot[3]);
    assign is_andi   = (opcode_is_imm)    & (funct3_one_hot[7]);
    assign is_ori    = (opcode_is_imm)    & (funct3_one_hot[6]);
    assign is_xori   = (opcode_is_imm)    & (funct3_one_hot[4]);
    assign is_slli   = (opcode_is_imm)    & (funct3_one_hot[1]) & (~funct7[5]);
    assign is_srli   = (opcode_is_imm)    & (funct3_one_hot[5]) & (~funct7[5]);
    assign is_srai   = (opcode_is_imm)    & (funct3_one_hot[5]) &  (funct7[5]);

    assign is_lui    = (opcode_is_lui);
    assign is_auipc  = (opcode_is_auipc);

    assign is_add    = (opcode_is_calc)   & (funct3_one_hot[0]) & (~funct7[5]);
    assign is_sub    = (opcode_is_calc)   & (funct3_one_hot[0]) &  (funct7[5]);
    assign is_slt    = (opcode_is_calc)   & (funct3_one_hot[2]);
    assign is_sltu   = (opcode_is_calc)   & (funct3_one_hot[3]);
    assign is_and    = (opcode_is_calc)   & (funct3_one_hot[7]);
    assign is_or     = (opcode_is_calc)   & (funct3_one_hot[6]);
    assign is_xor    = (opcode_is_calc)   & (funct3_one_hot[4]);
    assign is_sll    = (opcode_is_calc)   & (funct3_one_hot[1]) & (~funct7[5]);
    assign is_srl    = (opcode_is_calc)   & (funct3_one_hot[5]) & (~funct7[5]);
    assign is_sra    = (opcode_is_calc)   & (funct3_one_hot[5]) &  (funct7[5]);

    assign is_jal    = (opcode_is_jal);
    assign is_jalr   = (opcode_is_jalr)   & (funct3_one_hot[0]);

    assign is_beq    = (opcode_is_branch) & (funct3_one_hot[0]);
    assign is_bne    = (opcode_is_branch) & (funct3_one_hot[1]);
    assign is_blt    = (opcode_is_branch) & (funct3_one_hot[4]);
    assign is_bltu   = (opcode_is_branch) & (funct3_one_hot[6]);
    assign is_bge    = (opcode_is_branch) & (funct3_one_hot[5]);
    assign is_bgeu   = (opcode_is_branch) & (funct3_one_hot[7]);

    assign is_lw     = (opcode_is_load)   & (funct3_one_hot[2]); 
    assign is_lh     = (opcode_is_load)   & (funct3_one_hot[1]);
    assign is_lhu    = (opcode_is_load)   & (funct3_one_hot[5]);
    assign is_lb     = (opcode_is_load)   & (funct3_one_hot[0]);
    assign is_lbu    = (opcode_is_load)   & (funct3_one_hot[4]);
    assign is_sw     = (opcode_is_save)   & (funct3_one_hot[2]);
    assign is_sh     = (opcode_is_save)   & (funct3_one_hot[1]);
    assign is_sb     = (opcode_is_save)   & (funct3_one_hot[0]);

    assign is_ebreak = (opcode_is_csr)   && (rd == 5'b0) && (funct3 == 3'b0) && (inst[31:20] == 12'b1);
    assign is_ecall  = (opcode_is_csr)   && (rd == 5'b0) && (funct3 == 3'b0) && (inst[31:20] == 12'b0);

    assign is_csrrs  = (opcode_is_csr)   && (funct3_one_hot[2]);
    assign is_csrrw  = (opcode_is_csr)   && (funct3_one_hot[1]);
    assign is_mret   = (opcode_is_csr)   && (rd == 5'b0) && (funct3 == 3'b0) && (rs2 == 5'b10) && (funct7 == 7'b0011000); 

    assign alu_op[0]  = is_addi  |            // add
                        is_add   |
                        is_auipc |
                        is_jal   |
                        is_jalr  |
                        is_lw    |
                        is_lh    |
                        is_lhu   |
                        is_lb    |
                        is_lbu   |
                        is_sw    |
                        is_sh    |
                        is_sb;
    assign alu_op[1]  = is_sub;              // sub
    assign alu_op[2]  = is_slti  | is_slt  | // less than
                        is_blt;
    assign alu_op[3]  = is_sltiu | is_sltu | // less than unsigned
                        is_bltu;
    assign alu_op[4]  = is_andi  | is_and;   // and
    assign alu_op[5]  = is_ori   | is_or   | // or
                        is_csrrs;
    assign alu_op[6]  = is_xori  | is_xor;   // xor
    assign alu_op[7]  = is_slli  | is_sll;   // logical left shift
    assign alu_op[8]  = is_srli  | is_srl;   // logical right shift
    assign alu_op[9]  = is_srai  | is_sra;   // arithmetic right shift
    assign alu_op[10] = is_lui;              // select B src
    assign alu_op[11] = is_beq;              // equal
    assign alu_op[12] = is_bne;              // not equal
    assign alu_op[13] = is_bge;              // great equal than
    assign alu_op[14] = is_bgeu;             // great equal than unsigned

    /* SEXT mem out */
    assign mem_sext_width[0] = is_lb; // SEXT : 8 bit ->32 bit
    assign mem_sext_width[1] = is_lh; // SEXT : 16 bit->32 bit

    /* ZERO mem out */
    assign mem_zero_width[0] = is_lbu; // ZERO : 8bit ->32 bit
    assign mem_zero_width[1] = is_lhu; // ZERO : 16bit->32 bit

    assign branch_op[0] = is_jal;
    assign branch_op[1] = is_jalr;
    assign branch_op[2] = is_beq;
    assign branch_op[3] = is_bne;
    assign branch_op[4] = is_blt;
    assign branch_op[5] = is_bltu;
    assign branch_op[6] = is_bge;
    assign branch_op[7] = is_bgeu;

    assign branch_imm = (branch_op != 0) ? imm : 0;
    assign branch_rs1 = (branch_op != 0) ? reg_rdata1 : 0;
    assign branch_pc  = pc; 

    assign mem_valid = (opcode_is_save) | (opcode_is_load);
    assign mem_ren   = (opcode_is_load);
    assign mem_wen   = (opcode_is_save);
    assign mem_wdata = reg_rdata2;

    assign mem_wtype[0] = is_sb;
    assign mem_wtype[1] = is_sh;
    assign mem_wtype[2] = is_sw;

    assign mem_rtype[0] = is_lb | is_lbu;
    assign mem_rtype[1] = is_lh | is_lhu;
    assign mem_rtype[2] = is_lw;

    assign ecu_op[0] = (is_csrrs);
    assign ecu_op[1] = (is_csrrw);
    assign ecu_op[2] = (is_ecall);
    assign ecu_op[3] = (is_mret) ;

    assign ecu_pc = pc;

    assign ecu_csr_waddr = csr;

    assign break_ctrl = (is_ebreak == 1'b1) ? 1'b1 : 1'b0;

    assign imm_i = {{20{inst[31]}}, inst[31:20]};
    assign imm_s = {{20{inst[31]}}, inst[31:25], inst[11:7]};
    assign imm_b = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    assign imm_u = {inst[31:12], 12'b0};
    assign imm_j = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

    assign is_imm_i = (opcode_is_imm) | (opcode_is_jalr) | (opcode_is_load);
    assign is_imm_s = (opcode_is_save);
    assign is_imm_b = (opcode_is_branch);
    assign is_imm_u = (opcode_is_lui) | (opcode_is_auipc);
    assign is_imm_j = (opcode_is_jal);

    assign imm = ({DATA_WIDTH{is_imm_i}} & imm_i) |
                 ({DATA_WIDTH{is_imm_s}} & imm_s) |
                 ({DATA_WIDTH{is_imm_b}} & imm_b) |
                 ({DATA_WIDTH{is_imm_u}} & imm_u) |
                 ({DATA_WIDTH{is_imm_j}} & imm_j);

    assign alu_src1_reg = (opcode_is_imm)    |
                          (opcode_is_calc)   |
                          (opcode_is_branch) |
                          (opcode_is_load)   |
                          (opcode_is_save)   |
                          (is_csrrs);

    assign bru_src1_reg = (opcode_is_jalr); 

    assign ecu_src1_reg = (is_csrrs) | (is_csrrw);

    assign alu_src1_pc  = (opcode_is_auipc)  |
                          (opcode_is_jal  )  |
                          (opcode_is_jalr );

    assign alu_src2_reg = (opcode_is_calc)   |
                          (opcode_is_branch);

    assign mmu_src2_reg = (opcode_is_save);

    assign alu_src2_imm = (opcode_is_imm  )  |
                          (opcode_is_lui  )  |
                          (opcode_is_auipc)  |
                          (opcode_is_load )  |
                          (opcode_is_save );

    assign alu_src2_plus4 = (opcode_is_jal ) |
                            (opcode_is_jalr);

    assign alu_src2_csr = (opcode_is_csr);

    assign not_wr_reg  = (opcode_is_branch) |
                         (opcode_is_save)   |
                         (is_ecall)         |
                         (is_mret);

    assign reg_raddr1 = (alu_src1_reg | bru_src1_reg | ecu_src1_reg == 1'b1) ? rs1 : {ADDR_WIDTH{1'b0}};
    assign reg_raddr2 = (alu_src2_reg | mmu_src2_reg == 1'b1) ? rs2 : {ADDR_WIDTH{1'b0}};
    assign alu_src1 = (alu_src1_pc == 1'b1) ? pc : reg_rdata1;
    assign alu_src2 = (alu_src2_imm == 1'b1) ? imm : 
                      (alu_src2_plus4 == 1'b1) ? 4 : 
                      (alu_src2_csr == 1'b1)? csr_rdata : reg_rdata2;
    assign ecu_reg_rdata = (ecu_src1_reg == 1'b1) ? reg_rdata1 : {DATA_WIDTH{1'b0}};
    assign csr_raddr = ({`ysyx_24120013_CSR_ADDR_WIDTH{is_csrrs | is_csrrw}} & csr                  ) |
                       ({`ysyx_24120013_CSR_ADDR_WIDTH{is_ecall}}            & `ysyx_24120013_MTVEC ) |
                       ({`ysyx_24120013_CSR_ADDR_WIDTH{is_mret }}            & `ysyx_24120013_MEPC  );
    assign wr_reg_des = (not_wr_reg == 1'b1) ? {ADDR_WIDTH{1'b0}} : rd;

endmodule
