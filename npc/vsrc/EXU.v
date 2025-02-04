import "DPI-C" function void halt ();
`include "define/exu_command.v"

module ysyx_24120013_EXU #(ADDR_WIDTH = 5, DATA_WIDTH = 32)(
        input clk,
        input rst,
        input [DATA_WIDTH-1:0] src1,
        input [DATA_WIDTH-1:0] src2,
        input [ADDR_WIDTH-1:0] des_addr,
        input [`ysyx_24120013_ALUOP_WIDTH-1:0] alu_op,

        input break_ctrl,

        output wire reg_wen,
        output wire [ADDR_WIDTH-1:0] reg_waddr,
        output wire [DATA_WIDTH-1:0] reg_wdata,
        output wire [DATA_WIDTH-1:0] pc_jump_val,
        output wire pc_jump_en
        
    );

    assign reg_wen = (des_addr == 0) ? 1'b0 : 1'b1;
    assign reg_waddr = (des_addr == 0) ? {ADDR_WIDTH{1'b0}} : des_addr;
    assign reg_wdata = (des_addr == 0) ? {DATA_WIDTH{1'b0}} : alu_result;

    always @(*) begin
        if(break_ctrl) halt();
    end

    wire [DATA_WIDTH-1:0] alu_src1;
    wire [DATA_WIDTH-1:0] alu_src2;
    reg [DATA_WIDTH-1:0] alu_result;

    assign alu_src1 = src1;
    assign alu_src2 = src2;

ysyx_24120013_alu #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
)u_ysyx_24120013_alu(
    .src1       	(alu_src1        ),
    .src2       	(alu_src2        ),
    .alu_op    	(alu_op         ),
    .alu_result 	(alu_result      )
);


endmodule