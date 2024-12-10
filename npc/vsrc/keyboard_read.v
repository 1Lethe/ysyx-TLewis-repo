module keyboard_read(
    input clk,
    input rst,
    input [7:0] ps2read_data,
    input ps2read_ready,
    output wire ps2read_nextdata,
    output reg[7:0] ps2read_dataget,
    output reg ps2read_datarec
);

assign ps2read_nextdata = ~ps2read_ready;

always @(*) begin
    if(ps2read_datarec) begin
        $display("receive: %x",ps2read_dataget[7:0]);
    end
end

always @(posedge clk or negedge rst) begin
    if(rst) begin 
        ps2read_dataget <= 8'b0;
        ps2read_datarec <= 1'b0;
    end else if(ready) begin
        ps2read_dataget <= ps2read_data;
        ps2read_datarec <= 1'b1;
    end else begin
        ps2read_datarec <= 1'b0;
    end
end

endmodule