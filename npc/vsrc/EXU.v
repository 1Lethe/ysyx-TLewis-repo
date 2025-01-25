import "DPI-C" function void halt ();
`include "define/exu_command.v"

module ysyx_24120013_EXU #(COMMAND_WIDTH = 5, ADDR_WIDTH = 5, DATA_WIDTH = 32)(
        input clk,
        input rst,
        input [31:0] imm,
        input [DATA_WIDTH-1:0] src1,
        input [DATA_WIDTH-1:0] src2,
        input [ADDR_WIDTH-1:0] des_addr,
        input [COMMAND_WIDTH-1:0] command,

        output reg EXU_wen,
        output reg [ADDR_WIDTH-1:0] EXU_waddr,
        output reg [DATA_WIDTH-1:0] EXU_wdata
    );

    always @(*) begin
        if(des_addr == 0) begin
            EXU_wen = 0;
            EXU_waddr = 0;
        end
        else begin
            EXU_wen = 1;
            EXU_waddr = des_addr;
        end
    end

always @(*) begin
    case (command)
        `ysyx_24120013_ADD : 
            alu_command = `ysyx_24120013_ADD;
        default : 
            alu_command = {COMMAND_WIDTH{1'b0}};
    endcase
end

    always @(*) begin
        if(command == `ysyx_24120013_HALT)
            halt();
    end

wire [DATA_WIDTH-1:0] alu_src1;
wire [DATA_WIDTH-1:0] alu_src2;
reg [COMMAND_WIDTH-1:0] alu_command;
reg [DATA_WIDTH-1:0] alu_result;

assign alu_src1 = src1;
assign alu_src2 = src2;

ysyx_24120013_alu u_ysyx_24120013_alu(
    .src1       	(alu_src1        ),
    .src2       	(alu_src2        ),
    .command    	(alu_command     ),
    .alu_result 	(alu_result      )
);


endmodule