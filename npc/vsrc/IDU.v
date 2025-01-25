`include "define/exu_command.v"

module ysyx_24120013_IDU #(COMMAND_WIDTH = 4, ADDR_WIDTH = 5, DATA_WIDTH = 32)(
        input clk,
        input rst,
        input [DATA_WIDTH-1:0] inst,
        input [DATA_WIDTH-1:0] pc,
        input [DATA_WIDTH-1:0] rdata1,
        input [DATA_WIDTH-1:0] rdata2,
        output wire [ADDR_WIDTH-1:0] IDU_raddr1,
        output wire [ADDR_WIDTH-1:0] IDU_raddr2,

        output reg [DATA_WIDTH-1:0] IDU_src1,
        output reg [DATA_WIDTH-1:0] IDU_src2,
        output wire [ADDR_WIDTH-1:0] IDU_des,
        output reg [COMMAND_WIDTH-1:0] IDU_command
    );

    parameter IMM_I = 6'b000001;
    parameter IMM_U = 6'b000010;
    parameter IMM_S = 6'b000100;
    parameter IMM_J = 6'b001000;
    parameter IMM_R = 6'b010000;
    parameter IMM_B = 6'b100000;
    parameter IMM_N = 6'b000000;

    wire [2:0] funct3;
    wire [6:0] opcode;

    reg reg1_ren;
    reg reg2_ren;
    reg wren_en;
    reg [5:0] imm_type;
    reg [DATA_WIDTH-1:0] imm;

    assign opcode = inst[6:0];
    assign funct3 = inst[14:12]; 

    assign IDU_raddr1 = (reg1_ren == 1'b1) ? inst[19:15] : {ADDR_WIDTH{1'b0}};
    assign IDU_raddr2 = (reg2_ren == 1'b1) ? inst[24:20] : {ADDR_WIDTH{1'b0}};

    assign IDU_des = (wren_en == 1'b1) ? inst[11:7] : {ADDR_WIDTH{1'b0}};

    always @(*) begin
        case(imm_type)
            IMM_I : imm = {{20{inst[31]}}, inst[31:20]};
            IMM_U : imm = {{8{inst[31]}},inst[31:20],{12{1'b0}}};
            IMM_N : imm = {DATA_WIDTH{1'b0}};
            default : imm = {DATA_WIDTH{1'b0}};
        endcase
    end

    always @(*) begin
        case(opcode)
            7'b00100_11 : begin // addi
                if(funct3 == 3'b000) begin
                    imm_type = IMM_I;
                    IDU_command = `ysyx_24120013_ADD;
                    IDU_src1 = imm;
                    IDU_src2 = rdata1;
                    reg1_ren = 1'b1;
                    reg2_ren = 1'b0;
                    wren_en = 1'b1;
                end
                else begin
                    imm_type = 0;
                    IDU_command = {COMMAND_WIDTH{1'b0}};
                    IDU_src1 = 0;
                    IDU_src2 = 0;
                    reg1_ren = 0;
                    reg2_ren = 0;
                    wren_en = 0;
                end
            end
            7'b01101_11 : begin // lui
                imm_type = IMM_U;
                IDU_command = `ysyx_24120013_EQU;
                IDU_src1 = imm;
                IDU_src2 = 32'b0;
                reg1_ren = 1'b0;
                reg2_ren = 1'b0;
                wren_en = 1'b1;
            end
            7'b00101_11 : begin // auipc
                imm_type = IMM_U;
                IDU_command = `ysyx_24120013_ADD;
                IDU_src1 = pc;
                IDU_src2 = imm;
                reg1_ren = 1'b0;
                reg2_ren = 1'b0;
                wren_en = 1'b1;
            end
            7'b11100_11 : begin // ebreak
                imm_type = IMM_N;
                IDU_command = `ysyx_24120013_HALT;
                IDU_src1 = 0;
                IDU_src2 = 0;
                reg1_ren = 0;
                reg2_ren = 0;
                wren_en = 0;
            end
            default : begin
                imm_type = 0;
                IDU_command = {COMMAND_WIDTH{1'b0}};
                IDU_src1 = 0;
                IDU_src2 = 0;
                reg1_ren = 0;
                reg2_ren = 0;
                wren_en = 0;
            end
        endcase
    end

endmodule