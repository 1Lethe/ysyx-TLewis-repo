`timescale 1ns / 1ps
module keyboard_sim;

/* parameter */
parameter [31:0] clock_period = 10;

/* ps2_keyboard interface signals */
reg clk,clrn;
wire [7:0] data;
wire ready,overflow;
wire kbd_clk, kbd_data;
reg nextdata_n;

ps2_keyboard_model model(
    .ps2_clk(kbd_clk),
    .ps2_data(kbd_data)
);

ps2_keyboard inst(
    .clk(clk),
    .clrn(clrn),
    .ps2_clk(kbd_clk),
    .ps2_data(kbd_data), 
    .data(data),
    .ready(ready),
    .nextdata_n(nextdata_n),
    .overflow(overflow)
);

keyboard_display keyboard_display(
    .clk(clk),
    .rst(rst),
    .ps2dis_data(dataget),
    .ps2dis_recFlag(datarec_flag),
    .segs_enable(),
    .keytime_cnt(),
    .ps2dis_seg0_1(),
    .ps2dis_seg2_3(),
    .shift_flag()
);

wire rst;
reg[7:0] dataget;
reg datarec_flag;

initial begin /* clock driver */
    clk = 0;
    forever
        #(clock_period/2) clk = ~clk;
end

assign rst = ~clrn;
assign nextdata_n = ~ready;

always @(*) begin
    if(datarec_flag) begin
        $display("receive: %x",dataget[7:0]);
    end
end

always @(posedge clk or negedge rst) begin
    if(rst) begin 
        dataget <= 8'b0;
        datarec_flag <= 1'b0;
    end else if(ready) begin
        dataget <= data;
        datarec_flag <= 1'b1;
    end else begin
        datarec_flag <= 1'b0;
    end
end

initial begin
    clrn = 1'b0;  #20;
    clrn = 1'b1;  #20;
    model.kbd_sendcode(8'h12); // press 'SHIFT'
    model.kbd_sendcode(8'hF0);
    model.kbd_sendcode(8'h12);
    model.kbd_sendcode(8'h14); // press 'CTRL'
    model.kbd_sendcode(8'hF0);
    model.kbd_sendcode(8'h14);

    model.kbd_sendcode(8'h12);
    model.kbd_sendcode(8'h1C);
    model.kbd_sendcode(8'h1C);
    model.kbd_sendcode(8'hF0);
    model.kbd_sendcode(8'h1C);
    model.kbd_sendcode(8'hF0);
    model.kbd_sendcode(8'h12);
    
    model.kbd_sendcode(8'h1C); // press 'A'
    model.kbd_sendcode(8'hF0); // break code
    model.kbd_sendcode(8'h1C); // release 'A'
    model.kbd_sendcode(8'h1B); // press 'S'
    #20 model.kbd_sendcode(8'h1B); // keep pressing 'S'
    #20 model.kbd_sendcode(8'h1B); // keep pressing 'S'
    model.kbd_sendcode(8'hF0); // break code
    model.kbd_sendcode(8'h1B); // release 'S'
    #2000;
    $finish;
end

endmodule