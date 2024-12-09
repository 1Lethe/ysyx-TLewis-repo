module top(
    input clk,
    input buttom,
    input rst,
    output wire[7:0] seg0,
    output wire[7:0] seg1
);

wire [7:0] random_output;

RandomGen RandomGen(
    .clk(clk),
    .buttom(buttom),
    .rst(rst),
    .RandomGen_output(random_output)
);

segs segs(
    .segs_input(random_output),
    .seg0_output(seg0),
    .seg1_output(seg1)
);

endmodule