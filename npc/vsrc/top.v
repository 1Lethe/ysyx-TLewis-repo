module top(
    input clk,
    input rst,
    input ps2_clk,
    input ps2_data,
    output overflow
);

wire ps2_ready;
wire [7:0] data;
wire nextdata_n;

assign ready = ps2_ready;

keyboard_read keyboard_read(
    .clk(clk),
    .rst(rst),
    .ps2read_data(data),
    .ps2read_ready(ps2_ready),
    .ps2read_nextdata(),
    .ps2read_dataget(),
    .ps2read_datarec()
);

ps2_keyboard ps2_keyboard(
    .clk(clk),
    .clrn(~rst),
    .ps2_clk(ps2_clk),
    .ps2_data(ps2_data),
    .data(data),
    .ready(ps2_ready),
    .nextdata_n(nextdata_n),
    .overflow(overflow)
);

endmodule