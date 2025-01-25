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
        output reg [1:0] IDU_command
    );

    wire [2:0] funct3;
    wire [6:0] opcode;

    assign opcode = inst[6:0];
    assign funct3 = inst[14:12]; 
    assign IDU_raddr1 = inst[19:15];
    assign IDU_raddr2 = inst[24:20];
    assign IDU_des = inst[11:7];
    assign IDU_src1 = rdata1;
    assign IDU_src2 = rdata2;

    always @(*) begin
        case({funct3,opcode})
            10'b0000010011 : //addi
                IDU_imm = {{20{inst[31]}},inst[31:20]};
                IDU_command = 2'b01;
            7'b1110011 :
                IDU_command = 2'b11;
            default :
                IDU_command = 2'b00;
        endcase
    end

endmodule