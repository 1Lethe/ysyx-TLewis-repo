module ysyx_24120023_IFU #(DATA_WIDTH = 32)(
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] pc,
    output reg [DATA_WIDTH-1:0] IFU_inst
);

    always @(*) begin
        IFU_inst = (rst == 1'b1 || pc == 32'h80000000 - 4) ? {DATA_WIDTH{1'b0}} : sim_pmem_read(pc);
    end

endmodule
