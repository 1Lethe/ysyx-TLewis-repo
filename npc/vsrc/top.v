module top(
    input clk,
    input rst,
    input ps2_clk,
    input ps2_data,
    input ps2data_get_p,
    output ready,
    output overflow
);

reg nextdata_n;
wire ps2_ready;
wire [7:0] data;
reg[7:0] dataget;

assign ready = ps2_ready;

always @(posedge clk or negedge rst) begin
    if(rst) nextdata_n <= 1'b1;
    else nextdata_n <= ~ready;
end

always @(posedge clk or negedge rst) begin
    if(rst) dataget <= 8'b0;
    else if(ready) begin
        dataget <= data;
        $display("receive: %x",dataget[7:0]);
    end
end

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