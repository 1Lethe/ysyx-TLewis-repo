module ysyx_24120013_IDU #(COMMAND_WIDTH = 2, ADDR_WIDTH = 5, DATA_WIDTH = 32)(
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
        output reg [1:0] IDU_command
    );

    parameter R_TYPE = 6'b000001;
    parameter I_TYPE = 6'b000010;
    parameter S_TYPE = 6'b000100;
    parameter B_TYPE = 6'b001000;
    parameter U_TYPE = 6'b010000;
    parameter J_TYPE = 6'b100000;
    parameter N_TYPE = 6'b000000;

    wire [6:0] opcode;

    reg [5:0] imm_type;

    assign opcode = inst[6:0];
    assign IDU_raddr1 = inst[19:15];
    assign IDU_raddr2 = inst[24:20];
    assign IDU_des = inst[11:7];
    assign IDU_src1 = rdata1;
    assign IDU_src2 = rdata2;

    always @(*) begin
        case (opcode)
            7'b0010011 :
                imm_type = I_TYPE;
            default :
                imm_type = N_TYPE;
        endcase
    end

    always @(*) begin
        case (imm_type)
            I_TYPE :
                IDU_imm = {{20{inst[31]}},inst[31:20]};
            default :
                IDU_imm = 32'b0;
        endcase
    end

    always @(*) begin
        case(opcode)
            7'b0010011 :
                IDU_command = 2'b01;
            default :
                task halt;
        endcase
    end

endmodule