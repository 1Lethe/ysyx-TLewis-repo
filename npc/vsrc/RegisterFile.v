module ysyx_24120013_RegisterFile #(ADDR_WIDTH = 5, DATA_WIDTH = 32) (
        input clk,
        input rst,
        input [DATA_WIDTH-1:0] wdata,
        input [ADDR_WIDTH-1:0] waddr,
        input wen,
        input [ADDR_WIDTH-1:0] raddr1,
        input [ADDR_WIDTH-1:0] raddr2,
        output reg [DATA_WIDTH-1:0] rdata1,
        output reg [DATA_WIDTH-1:0] rdata2
    );

    reg [DATA_WIDTH-1:0] rf [2**ADDR_WIDTH-1:0];

    always @(posedge clk) begin
        if(wen) begin
            rf[waddr] <= wdata;
        end
        rf[0] <= {DATA_WIDTH{1'b0}};
    end

    always @(posedge clk) begin
        if(rst) begin
            rdata1 <= {DATA_WIDTH{1'b0}};
            rdata2 <= {DATA_WIDTH{1'b0}};
        end
        else begin
            rdata1 <= rf[raddr1];
            rdata2 <= rf[raddr2];
        end
    end

endmodule
