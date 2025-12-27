`include "define/exu_command.v"

module ysyx_24120013_lsu #(MEM_WIDTH = 32, DATA_WIDTH = 32)(
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
    output wire [DATA_WIDTH-1:0] mem_wreg,
    output wire mem_wcomplete,
    output wire mem_rvalid,
    output wire mem_access_flag,

    output wire simplebus_lsu_mem_wr_req,
    output wire [MEM_WIDTH-1:0] simplebus_lsu_mem_wr_addr,
    output wire [DATA_WIDTH-1:0] simplebus_lsu_mem_wr_data,
    output wire [3:0] simplebus_lsu_mem_wr_mask,
    output wire [2:0] simplebus_lsu_mem_wr_prot,
    input [1:0]  simplebus_lsu_mem_wr_resp,
    input simplebus_lsu_mem_wr_complete,

    output wire simplebus_lsu_mem_rd_req,
    output wire [MEM_WIDTH-1:0] simplebus_lsu_mem_rd_addr,
    output wire [2:0] simplebus_lsu_mem_rd_prot,
    input [DATA_WIDTH-1:0] simplebus_lsu_mem_rd_data,
    input [1:0]  simplebus_lsu_mem_rd_resp,
    input simplebus_lsu_mem_rd_complete
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

    wire [7:0] mem_wmask_8bit;
    assign mem_wmask_8bit = (is_sw_align_mem) ? 8'b00001111 : 
                            (is_sh_align_mem) ? 8'b00000011 << mem_waddr[1:0] : 
                            (is_sb_mem) ? 8'b00000001 << mem_waddr[1:0] : 8'b0;
    wire [7:0] mem_rmask_8bit;
    assign mem_rmask_8bit = (mem_rtype[2] == 1'b1) ? 8'b00001111 : 
                            (mem_rtype[1] == 1'b1) ? 8'b00000011 << mem_raddr[1:0] : 
                            (mem_rtype[0] == 1'b1) ? 8'b00000001 << mem_raddr[1:0] : 8'b0;

    wire [3:0] mem_wmask;
    assign mem_wmask = mem_wmask_8bit[3:0];

    wire [3:0] mem_rmask;
    assign mem_rmask = mem_rmask_8bit[3:0];

    reg mem_wen_r1;
    reg mem_ren_r1;
    always @(posedge clk) begin
        if(rst)
            mem_wen_r1 <= 1'b0;
        else
            mem_wen_r1 <= mem_wen;
    end

    always @(posedge clk) begin
        if(rst)
            mem_ren_r1 <= 1'b0;
        else
            mem_ren_r1 <= mem_ren;
    end

    wire mem_wen_pos;
    wire mem_ren_pos;
    assign mem_wen_pos = mem_wen & ~mem_wen_r1;
    assign mem_ren_pos = mem_ren & ~mem_ren_r1;

    assign mem_access_flag = mem_wen_pos | mem_ren_pos;

    assign simplebus_lsu_mem_wr_req = mem_wen_pos;
    assign simplebus_lsu_mem_wr_addr = mem_waddr;
    assign simplebus_lsu_mem_wr_data = mem_wdata_align;
    assign simplebus_lsu_mem_wr_mask = mem_wmask;
    assign simplebus_lsu_mem_wr_prot = 3'b000;
    assign mem_wcomplete = simplebus_lsu_mem_wr_complete;

    assign simplebus_lsu_mem_rd_req = mem_ren_pos;
    assign simplebus_lsu_mem_rd_addr = mem_raddr;
    assign simplebus_lsu_mem_rd_prot = 3'b000;
    assign mem_rdata = simplebus_lsu_mem_rd_data;
    assign mem_rvalid = simplebus_lsu_mem_rd_complete;

endmodule