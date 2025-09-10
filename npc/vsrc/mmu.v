`include "define/exu_command.v"

module ysyx_24120013_mmu #(MEM_WIDTH = 32, DATA_WIDTH = 32)(
    input clk,
    input rst,
    input mem_valid,
    input mem_ren,
    input mem_wen,
    input [DATA_WIDTH-1:0] alu_result,
    input [7:0] mem_wtype,
    input [7:0] mem_rtype,
    input [`ysyx_24120013_ZERO_WIDTH-1:0] mem_zero_width,
    input [`ysyx_24120013_SEXT_WIDTH-1:0] mem_sext_width,
    input [DATA_WIDTH-1:0] mem_wdata,
    output reg [DATA_WIDTH-1:0] mem_wreg
    );

    wire [DATA_WIDTH-1:0] mem_rdata;
    wire [MEM_WIDTH-1:0] mem_waddr;
    wire [MEM_WIDTH-1:0] mem_raddr;

    wire is_sb_mem;
    wire is_sh_align_mem;
    wire is_sw_align_mem;

    wire [DATA_WIDTH-1:0] sh_maskd_data;
    wire [DATA_WIDTH-1:0] sb_maskd_data;

    wire [DATA_WIDTH-1:0] mem_wdata_align;

    assign is_sb_mem = (mem_wtype[0] == 1'b1);
    assign is_sh_align_mem = (mem_wtype[1] == 1'b1 && mem_waddr[0] == 1'b0);
    assign is_sw_align_mem = (mem_wtype[2] == 1'b1 && mem_waddr[1:0] == 2'b0);

    assign mem_waddr = (mem_valid == 1'b1 && mem_wen == 1'b1) ? alu_result : 0;
    assign mem_raddr = (mem_valid == 1'b1 && mem_ren == 1'b1) ? alu_result : 0;

    assign sh_maskd_data = mem_wdata << {mem_waddr[1:0], 3'b000};
    assign sb_maskd_data = mem_wdata << {mem_waddr[1:0], 3'b000};

    assign mem_wdata_align = ({DATA_WIDTH{is_sw_align_mem}} & mem_wdata) |
                             ({DATA_WIDTH{is_sh_align_mem}} & (sh_maskd_data)) |
                             ({DATA_WIDTH{is_sb_mem}} & (sb_maskd_data));

    wire mem_sext_flag;
    wire [DATA_WIDTH-1:0] mem_sext_res;
    wire [DATA_WIDTH-1:0] mem_sext_8_32bit;
    wire [DATA_WIDTH-1:0] mem_sext_16_32bit;

    wire mem_zero_flag;
    wire [DATA_WIDTH-1:0] mem_zero_res;
    wire [DATA_WIDTH-1:0] mem_zero_8_32bit;
    wire [DATA_WIDTH-1:0] mem_zero_16_32bit;

    wire [7:0] mem_rdata_maskd_8bit;
    wire [15:0] mem_rdata_maskd_16bit;

    wire mem_not_ex;

    wire [7:0]  byte0 = mem_rdata[7:0];
    wire [7:0]  byte1 = mem_rdata[15:8];
    wire [7:0]  byte2 = mem_rdata[23:16];
    wire [7:0]  byte3 = mem_rdata[31:24];

    assign mem_rdata_maskd_8bit = 
        ({8{mem_rmask[0]}} & byte0) |
        ({8{mem_rmask[1]}} & byte1) |
        ({8{mem_rmask[2]}} & byte2) |
        ({8{mem_rmask[3]}} & byte3);

    assign mem_rdata_maskd_16bit = 
        (mem_rmask[1] & mem_rmask[0]) ? {byte1, byte0} : // 地址0-1
        (mem_rmask[3] & mem_rmask[2]) ? {byte3, byte2} : // 地址2-3
        16'b0;

    assign mem_sext_flag = (mem_sext_width != 0);
    assign mem_sext_8_32bit  = {{24{mem_rdata_maskd_8bit[7]}},  mem_rdata_maskd_8bit};
    assign mem_sext_16_32bit = {{16{mem_rdata_maskd_16bit[15]}}, mem_rdata_maskd_16bit};

    assign mem_sext_res = ({DATA_WIDTH{mem_sext_width[0]}} & mem_sext_8_32bit)  |
                          ({DATA_WIDTH{mem_sext_width[1]}} & mem_sext_16_32bit);

    assign mem_zero_flag = (mem_zero_width != 0);
    assign mem_zero_8_32bit  = {{24{1'b0}}, mem_rdata_maskd_8bit};
    assign mem_zero_16_32bit = {{16{1'b0}}, mem_rdata_maskd_16bit};

    assign mem_zero_res = ({DATA_WIDTH{mem_zero_width[0]}} & mem_zero_8_32bit)  |
                          ({DATA_WIDTH{mem_zero_width[1]}} & mem_zero_16_32bit);

    assign mem_not_ex = (~mem_sext_flag & ~mem_zero_flag);

    assign mem_wreg = ({DATA_WIDTH{mem_sext_flag}} & mem_sext_res) |
                      ({DATA_WIDTH{mem_zero_flag}} & mem_zero_res) |
                      ({DATA_WIDTH{mem_not_ex   }} & mem_rdata);

    wire [7:0] mem_wmask;
    assign mem_wmask = (is_sw_align_mem) ? 8'b00001111 : 
                       (is_sh_align_mem) ? 8'b00000011 << mem_waddr[1:0] : 
                       (is_sb_mem) ? 8'b00000001 << mem_waddr[1:0] : 8'b0;
    wire [7:0] mem_rmask;
    assign mem_rmask = (mem_rtype[2] == 1'b1) ? 8'b00001111 : 
                       (mem_rtype[1] == 1'b1) ? 8'b00000011 << mem_raddr[1:0] : 
                       (mem_rtype[0] == 1'b1) ? 8'b00000001 << mem_raddr[1:0] : 8'b0;

    assign mem_rdata = (mem_valid == 1'b1 && mem_ren == 1'b1) ? sim_pmem_read(mem_raddr) : 0;

    always @(posedge clk) begin
        if (mem_valid & mem_wen) begin // 有写请求时
            sim_pmem_write(mem_waddr, mem_wdata_align, mem_wmask);
        end
    end

endmodule