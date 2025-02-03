module ysyx_24120023_IFU (
    input clk,
    input rst,
    input [31:0] pmem,
    output wire [31:0] IFU_inst
);

    assign IFU_inst = pmem;

endmodule
