module RandomGen (
    input clk,
    input rst,
    output wire [7:0]RandomGen_output
);

reg[7:0] shift_reg;

always @(negedge clk or negedge rst) begin
    if(rst) shift_reg <= 8'b11111111;
    else begin
        shift_reg <= {shift_reg[4]^shift_reg[3]^shift_reg[2]^shift_reg[0],shift_reg[7:1]};
    end
end

assign RandomGen_output = shift_reg; 

endmodule
