`include "define/exu_command.v"

module ysyx_24120013_IDU #(COMMAND_WIDTH = 4, ADDR_WIDTH = 5, DATA_WIDTH = 32)(
        input clk,
        input rst,
        input [31:0] inst,
        input [DATA_WIDTH-1:0] rdata1,
        input [DATA_WIDTH-1:0] rdata2,
        output wire [ADDR_WIDTH-1:0] IDU_raddr1,
        output wire [ADDR_WIDTH-1:0] IDU_raddr2,

        output wire [DATA_WIDTH-1:0] IDU_src1,
        output wire [DATA_WIDTH-1:0] IDU_src2,
        output wire [ADDR_WIDTH-1:0] IDU_des,
        output reg [31:0] IDU_imm,
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

    reg [5:0] imm_type;
    reg src1_en;
    reg src2_en;
    reg write_en;

    assign opcode = inst[6:0];
    assign funct3 = inst[14:12]; 

    assign IDU_raddr1 = (src1_en == 1'b1) ? inst[19:15] : 5'b0;
    assign IDU_src1 = (src1_en == 1'b1) ? rdata1 : 5'b0;

    assign IDU_raddr2 = (src2_en == 1'b1) ? inst[24:20] : 5'b0;
    assign IDU_src2 = (src2_en == 1'b1) ? rdata2 : 5'b0;

    assign IDU_des = (write_en == 1'b1) ? inst[11:7] : 5'b0;

    always @(*) begin
        case(imm_type)
            IMM_I : IDU_imm = {{20{inst[31]}}, inst[31:20]};
            IMM_N : IDU_imm = {DATA_WIDTH{1'b0}};
            default : IDU_imm = {DATA_WIDTH{1'b0}};
        endcase
    end

    always @(*) begin
        case({funct3,opcode})
            10'b0000010011 : begin // addi
                imm_type = IMM_I;
                IDU_command = `ysyx_24120013_ADD;
                src1_en = 1'b1;
                write_en = 1'b1;
            end
            10'b0001110011 : begin // ebreak
                imm_type = IMM_N;
                IDU_command = `ysyx_24120013_HALT;
            end
            default :
                IDU_command = {COMMAND_WIDTH{1'b0}};
        endcase
    end

endmodule