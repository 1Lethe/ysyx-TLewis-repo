module RandomGen (
    input clk,
    input buttom,
    input rst,
    output wire [7:0]RandomGen_output
);

reg buttom_reg1;
wire buttom_posedge;
reg[7:0] shift_reg;

always @(posedge clk or negedge rst) begin
    if(rst) buttom_reg1 <= 1'b0;
    else begin
        buttom_reg1 <= buttom;
    end
end

assign buttom_posedge = buttom || (~buttom_reg1); 

always @(posedge clk or negedge rst) begin
    if(rst) shift_reg <= 8'b11111111;
    else if(buttom_posedge == 1'b1) begin
        shift_reg <= {shift_reg[4]^shift_reg[3]^shift_reg[2]^shift_reg[0],shift_reg[7:1]};
    end
    else
        shift_reg <= shift_reg;
end

assign RandomGen_output = shift_reg; 

endmodule
