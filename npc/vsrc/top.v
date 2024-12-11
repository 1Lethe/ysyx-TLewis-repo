module top(
    input clk,
    input rst,
    input ps2_clk,
    input ps2_data,
    output wire [7:0] o_seg0,
    output wire [7:0] o_seg1,
    output wire [7:0] o_seg2,
    output wire [7:0] o_seg3,
    output wire [7:0] o_seg4,
    output wire [7:0] o_seg5,
    output wire shift,
    output wire ctrl
);

wire overflow;
wire ps2_ready;
wire [7:0] data;
wire nextdata_n;
wire [7:0]dataget;
wire datarec;
wire segs_enable;
wire [7:0]seg0_1;
wire [7:0]seg2_3;
wire [7:0]seg4_5;


segs segs(
    .segs_input0_1(seg0_1),
    .segs_input2_3(seg2_3),
    .segs_input4_5(seg4_5),
    .segs_enable(segs_enable),
    .seg0_output(o_seg0),
    .seg1_output(o_seg1),
    .seg2_output(o_seg2),
    .seg3_output(o_seg3),
    .seg4_output(o_seg4),
    .seg5_output(o_seg5)
);

keyboard_display keyboard_display(
    .clk(clk),
    .rst(rst),
    .ps2dis_data(dataget),
    .ps2dis_recFlag(datarec),
    .segs_enable(segs_enable),
    .ps2dis_seg0_1(seg0_1),
    .ps2dis_seg2_3(seg2_3),
    .keytime_cnt(seg4_5),
    .shift_flag(shift),
    .ctrl_flag(ctrl)
);

keyboard_read keyboard_read(
    .clk(clk),
    .rst(rst),
    .ps2read_data(data),
    .ps2read_ready(ps2_ready),
    .ps2read_nextdata(nextdata_n),
    .ps2read_dataget(dataget),
    .ps2read_datarec(datarec)
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