`include "define/exu_command.v"

module ysyx_24120013_alu #(COMMAND_WIDTH = 4, ADDR_WIDTH = 5, DATA_WIDTH = 32)(
    input [DATA_WIDTH-1:0] src1,
    input [DATA_WIDTH-1:0] src2,
    input [COMMAND_WIDTH-1:0] command,

    output reg [DATA_WIDTH-1:0] alu_result
);

always @(*) begin
    case(command)
        `ysyx_24120013_ADD : alu_result = src1 + src2;
        `ysyx_24120013_EQU : alu_result = src1;
        default : alu_result = {DATA_WIDTH{1'b0}};
    endcase
end

endmodule