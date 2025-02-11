`include "define/exu_command.v"

module ysyx_24120013_EXU #(MEM_WIDTH = 32, ADDR_WIDTH = 5, DATA_WIDTH = 32)(
        input clk,
        input rst,

        input [DATA_WIDTH-1:0] alu_src1,
        input [DATA_WIDTH-1:0] alu_src2,
        input [`ysyx_24120013_ALUOP_WIDTH-1:0] alu_op,

        input [DATA_WIDTH-1:0] branch_imm,
        input [DATA_WIDTH-1:0] branch_rs1,
        input [DATA_WIDTH-1:0] branch_pc,
        input [`ysyx_24120013_BRANCH_WIDTH-1:0] branch_op,

        input mem_valid,
        input mem_ren,
        input mem_wen,
        input [DATA_WIDTH-1:0] mem_wdata,
        input [7:0] mem_wtype,
        input [7:0] mem_rtype,
        input [`ysyx_24120013_ZERO_WIDTH-1:0] mem_zero_width,
        input [`ysyx_24120013_SEXT_WIDTH-1:0] mem_sext_width,

        input break_ctrl,

        input [ADDR_WIDTH-1:0] wr_reg_des,

        output wire reg_wen,
        output wire [ADDR_WIDTH-1:0] reg_waddr,
        output wire [DATA_WIDTH-1:0] reg_wdata,
        output wire [DATA_WIDTH-1:0] branch_jmp_pc
    );

    wire [DATA_WIDTH-1:0] mem_rdata;
    wire [DATA_WIDTH-1:0] mem_wreg;
    wire [MEM_WIDTH-1:0] mem_waddr;
    wire [MEM_WIDTH-1:0] mem_raddr;

    assign mem_waddr = (mem_valid & mem_wen == 1'b1) ? alu_result : 0;
    assign mem_raddr = (mem_valid & mem_ren == 1'b1) ? alu_result : 0;

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

    assign mem_rdata_maskd_8bit = ({8{mem_rmask[0]}} & mem_rdata[7:0])   | 
                                  ({8{mem_rmask[1]}} & mem_rdata[15:8])  |
                                  ({8{mem_rmask[2]}} & mem_rdata[23:16]) |
                                  ({8{mem_rmask[3]}} & mem_rdata[31:24]);

    assign mem_rdata_maskd_16bit = {({8{mem_rmask[3]}} & mem_rdata[31:24]) | 
                                    ({8{mem_rmask[1]}} & mem_rdata[15:8 ]),
                                    ({8{mem_rmask[2]}} & mem_rdata[23:16]) |
                                    ({8{mem_rmask[0]}} & mem_rdata[7 :0 ])};

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
    assign mem_wmask = (mem_wtype[2] == 1'b1) ? 8'b00001111 : 
                       (mem_wtype[1] == 1'b1) ? 8'b00000011 << mem_waddr[1:0] : 8'b00000001 << mem_waddr[1:0];

    wire [7:0] mem_rmask;
    assign mem_rmask = (mem_rtype[2] == 1'b1) ? 8'b00001111 : 
                       (mem_rtype[1] == 1'b1) ? 8'b00000011 << mem_raddr[1:0] : 8'b00000001 << mem_raddr[1:0];

    assign reg_wen = (wr_reg_des == 0) ? 1'b0 : 1'b1;
    assign reg_waddr = (wr_reg_des == 0) ? {ADDR_WIDTH{1'b0}} : wr_reg_des;
    assign reg_wdata = (wr_reg_des == 0) ? {DATA_WIDTH{1'b0}} : 
                       (mem_valid & mem_ren == 1'b1) ? mem_wreg : alu_result;

    always @(*) begin
        if(break_ctrl) halt();
    end

    wire [DATA_WIDTH-1:0] alu_result;

    wire branch_less;
    wire branch_zero;


ysyx_24120013_alu #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
)u_ysyx_24120013_alu(
    .src1       	(alu_src1       ),
    .src2       	(alu_src2       ),
    .alu_op    	    (alu_op         ),
    .alu_result 	(alu_result     ),
    .branch_less    (branch_less    ),
    .branch_zero    (branch_zero    )
);

// output declaration of module ysyx_24120013_branch_ctrl
ysyx_24120013_bru #(
    .DATA_WIDTH(DATA_WIDTH)
)u_ysyx_24120013_bru(
    .clk           	(clk            ),
    .rst           	(rst            ),
    .branch_less    (branch_less    ),
    .branch_zero    (branch_zero    ),
    .branch_op     	(branch_op      ),
    .branch_imm    	(branch_imm     ),
    .branch_rs1    	(branch_rs1     ),
    .branch_pc     	(branch_pc      ),
    .branch_jmp_pc 	(branch_jmp_pc  )
);

// output declaration of module ysyx_24120013_mmu
ysyx_24120013_mmu #(
    .MEM_WIDTH(MEM_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
)u_ysyx_24120013_mmu(
    .clk       	(clk        ),
    .rst       	(rst        ),
    .mem_valid 	(mem_valid  ),
    .mem_ren    (mem_ren    ),
    .mem_wen   	(mem_wen    ),
    .mem_waddr 	(mem_waddr  ),
    .mem_wdata 	(mem_wdata  ),
    .mem_wmask 	(mem_wmask  ),
    .mem_raddr 	(mem_raddr  ),
    .mem_rdata 	(mem_rdata  )
);

endmodule