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

    wire [DATA_WIDTH-1:0] alu_result;

    wire [DATA_WIDTH-1:0] mem_wreg;

    wire branch_less;
    wire branch_zero;

    assign reg_wen = (wr_reg_des == 0) ? 1'b0 : 1'b1;
    assign reg_waddr = (wr_reg_des == 0) ? {ADDR_WIDTH{1'b0}} : wr_reg_des;
    assign reg_wdata = (wr_reg_des == 0) ? {DATA_WIDTH{1'b0}} : 
                       (mem_valid & mem_ren == 1'b1) ? mem_wreg : alu_result;

    always @(*) begin
        if(break_ctrl) halt();
    end

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
    .clk       	    (clk             ),
    .rst       	    (rst             ),
    .mem_valid 	    (mem_valid       ),
    .mem_ren        (mem_ren         ),
    .mem_wen   	    (mem_wen         ),
    .alu_result     (alu_result      ),
    .mem_wtype      (mem_wtype       ),
    .mem_rtype      (mem_rtype       ),
    .mem_zero_width (mem_zero_width  ),
    .mem_sext_width (mem_sext_width  ),
    .mem_wdata  	(mem_wdata       ),
    .mem_wreg       (mem_wreg        )
);

endmodule