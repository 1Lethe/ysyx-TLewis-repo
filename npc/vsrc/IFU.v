module ysyx_24120023_IFU (
    input clk,
    input rst,
    input [31:0] inst,
    output wire IFU_inst
);

assign IFU_inst = inst;

endmodule
