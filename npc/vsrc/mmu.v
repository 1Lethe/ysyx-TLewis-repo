`include "define/exu_command.v"

module ysyx_24120013_mmu #(MEM_WIDTH = 32, DATA_WIDTH = 32)(
    input clk,
    input rst,
    input mem_valid,
    input mem_ren,
    input mem_wen,

    input [MEM_WIDTH-1:0] mem_waddr,
    input [DATA_WIDTH-1:0] mem_wdata,
    input [7:0] mem_wmask,

    input [MEM_WIDTH-1:0] mem_raddr,
    output reg [DATA_WIDTH-1:0] mem_rdata
    );

    assign mem_rdata = (mem_valid & mem_ren == 1'b1) ? sim_pmem_read(mem_raddr) : 0;

    always @(posedge clk) begin
        if (mem_valid & mem_wen) begin // 有写请求时
            sim_pmem_write(mem_waddr, mem_wdata, mem_wmask);
        end
    end


endmodule