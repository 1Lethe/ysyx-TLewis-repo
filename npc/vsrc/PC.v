module ysyx_24120013_PC (
    input clk,
    input rst,
    input pc_jmp_en,
    input pc_jmp_val,
    output reg[31:0] pc
);

always @(posedge clk) begin
    if(rst)
        pc <= 32'h80000000;
    else if(pc_jmp_en) begin
        pc <= pc_jmp_val;
    end
    else
        pc <= pc + 1;
end

endmodule
