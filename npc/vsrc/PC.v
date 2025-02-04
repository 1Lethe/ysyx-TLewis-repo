module ysyx_24120013_PC #(DATA_WIDTH = 32)(
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] pc_jmp_val,
    output reg[DATA_WIDTH-1:0] pc
);

always @(posedge clk) begin
    if(rst)
        pc <= 32'h80000000 - 4;
    else begin
        pc <= pc_jmp_val;
    end
end

endmodule
