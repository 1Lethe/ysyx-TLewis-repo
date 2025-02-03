`include "define/exu_command.v"

module ysyx_24120013_alu #(ADDR_WIDTH = 5, DATA_WIDTH = 32)(
    input [DATA_WIDTH-1:0] src1,
    input [DATA_WIDTH-1:0] src2,
    input [`ysyx_24120013_ALUOP_WIDTH-1:0] alu_op,

    output reg [DATA_WIDTH-1:0] alu_result
);

    wire [DATA_WIDTH-1:0] add_res;
    wire [DATA_WIDTH-1:0] and_res;
    wire [DATA_WIDTH-1:0] or_res;
    wire [DATA_WIDTH-1:0] xor_res;
    wire [DATA_WIDTH-1:0] src2_res;

    assign add_res = src1 + src2;
    assign and_res = src1 & src2;
    assign or_res  = src1 | src2;
    assign src2_res = src2;

    assign alu_result = ({DATA_WIDTH{alu_op[0]}} & add_res) |
                        ({DATA_WIDTH{alu_op[10]}}& src2_res);

endmodule