module ysyx_24120023_IFU (
    input clk,
    input rst,
    input [31:0] inst,
    output reg [31:0] IFU_inst,
    output wire halt_flag
);

always @(posedge clk) begin
    if(rst)
        IFU_inst <= 32'b0;
    else
        IFU_inst <= inst;
end

endmodule
