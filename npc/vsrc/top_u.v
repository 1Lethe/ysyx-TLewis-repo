import "DPI-C" function void halt (void);

wire clk;
wire rst;
wire [31:0] pmem;
wire [31:0] pc;

initial begin
    
end

module top(
    .clk(clk),
    .rst(rst),
    .pmem(pmem),
    .pc(pc)
);