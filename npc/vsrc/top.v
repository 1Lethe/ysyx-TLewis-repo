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
reg datarec_flag;
reg[7:0] dataget;
wire ps2_ready;
wire [7:0] data;

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
assign ready = ps2_ready;

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