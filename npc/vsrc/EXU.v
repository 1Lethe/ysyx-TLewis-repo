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
        output wire mem_access_flag,

        input [`ysyx_24120013_ECU_WIDTH-1:0] ecu_op,
        input [DATA_WIDTH-1:0] ecu_pc,
        input [DATA_WIDTH-1:0] ecu_reg_rdata,
        input [`ysyx_24120013_CSR_ADDR_WIDTH-1:0] ecu_csr_waddr,
        input [DATA_WIDTH-1:0] csr_rdata,

        input break_ctrl,

        input [ADDR_WIDTH-1:0] wr_reg_des,

        output wire reg_wen,
        output wire [ADDR_WIDTH-1:0] reg_waddr,
        output wire [DATA_WIDTH-1:0] reg_wdata,

        output wire csr_wen,
        output wire [`ysyx_24120013_CSR_ADDR_WIDTH-1:0] csr_waddr1,
        output wire [DATA_WIDTH-1:0] csr_wdata1,
        output wire [`ysyx_24120013_CSR_ADDR_WIDTH-1:0] csr_waddr2,
        output wire [DATA_WIDTH-1:0] csr_wdata2,
        output wire [`ysyx_24120013_CSR_ADDR_WIDTH-1:0] csr_waddr3,
        output wire [DATA_WIDTH-1:0] csr_wdata3,

        output wire [DATA_WIDTH-1:0] branch_jmp_pc,

        input id_is_valid,
        output wire ex_is_ready,

        input wb_is_ready,
        output wire ex_is_valid,

        output  m_axi_pmem_lsu_awvalid,
        input wire s_axi_pmem_lsu_awready,
        output  [MEM_WIDTH-1:0] m_axi_pmem_lsu_awaddr,
        output  [2:0] m_axi_pmem_lsu_awprot,

        output  m_axi_pmem_lsu_wvalid,
        input wire s_axi_pmem_lsu_wready,
        output  [DATA_WIDTH-1:0] m_axi_pmem_lsu_wdata,
        output  [3:0] m_axi_pmem_lsu_wstrb,

        input wire s_axi_pmem_lsu_bvalid,
        output  m_axi_pmem_lsu_bready,
        input wire [1:0] s_axi_pmem_lsu_bresp,

        output  m_axi_pmem_lsu_arvalid,
        input wire s_axi_pmem_lsu_arready,
        output  [MEM_WIDTH-1:0] m_axi_pmem_lsu_araddr,
        output  [2:0] m_axi_pmem_lsu_arprot,

        input wire s_axi_pmem_lsu_rvalid,
        output  m_axi_pmem_lsu_rready,
        input wire [DATA_WIDTH-1:0] s_axi_pmem_lsu_rdata,
        input wire [1:0] s_axi_pmem_lsu_rresp
    );

    wire ex_shakehand;
    wire mem_rvalid;
    wire mem_wcomplete;
    assign ex_is_ready = ~rst;
    assign ex_is_valid = (id_is_valid == 1'b1) && ((mem_ren == 1'b1) ? mem_rvalid : 1'b1) 
                        && ((mem_wen == 1'b1) ? mem_wcomplete : 1'b1);

    assign ex_shakehand = id_is_valid & ex_is_ready;

    wire [DATA_WIDTH-1:0] alu_result;

    wire mem_valid_shaked;
    wire [DATA_WIDTH-1:0] mem_wreg;

    assign mem_valid_shaked = mem_valid & ex_shakehand;

    assign reg_wen = (wr_reg_des == 0 || ex_is_valid == 1'b0) ? 1'b0 : 1'b1;
    assign reg_waddr = (wr_reg_des == 0 || ex_is_valid == 1'b0) ? {ADDR_WIDTH{1'b0}} : wr_reg_des;
    assign reg_wdata = (wr_reg_des == 0 || ex_is_valid == 1'b0) ? {DATA_WIDTH{1'b0}} : 
                       (mem_valid & mem_ren == 1'b1) ? mem_wreg : alu_result;

    wire ecu_csr_wen;

    assign csr_wen = ecu_csr_wen & ex_shakehand;

    always @(*) begin
        if(break_ctrl) halt();
    end

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
    .clk           	  (clk              ),
    .rst           	  (rst              ),
    .branch_less      (branch_less      ),
    .branch_zero      (branch_zero      ),
    .branch_op   	  (branch_op        ),
    .branch_imm    	  (branch_imm       ),
    .branch_rs1    	  (branch_rs1       ),
    .branch_pc     	  (branch_pc        ),
    .ecu_jump_pc_flag (ecu_jump_pc_flag ),
    .ecu_jump_pc      (ecu_jump_pc      ),
    .branch_jmp_pc 	  (branch_jmp_pc    )
);

// output declaration of module ysyx_24120013_lsu

ysyx_24120013_lsu #(
    .MEM_WIDTH(MEM_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
)u_ysyx_24120013_lsu(
    .clk       	    (clk             ),
    .rst       	    (rst             ),
    .mem_valid 	    (mem_valid_shaked),
    .mem_ren        (mem_ren         ),
    .mem_wen   	    (mem_wen         ),
    .alu_result     (alu_result      ),
    .mem_wtype      (mem_wtype       ),
    .mem_rtype      (mem_rtype       ),
    .mem_zero_width (mem_zero_width  ),
    .mem_sext_width (mem_sext_width  ),
    .mem_wdata  	(mem_wdata       ),
    .mem_wreg       (mem_wreg        ),
    .mem_wcomplete  (mem_wcomplete   ),
    .mem_rvalid     (mem_rvalid      ),
    .mem_access_flag(mem_access_flag ),

    .m_axi_pmem_awvalid   (m_axi_pmem_lsu_awvalid   ),
    .s_axi_pmem_awready   (s_axi_pmem_lsu_awready   ),
    .m_axi_pmem_awaddr    (m_axi_pmem_lsu_awaddr    ),
    .m_axi_pmem_awprot    (m_axi_pmem_lsu_awprot    ),

    .m_axi_pmem_wvalid    (m_axi_pmem_lsu_wvalid    ),
    .s_axi_pmem_wready    (s_axi_pmem_lsu_wready    ),
    .m_axi_pmem_wdata     (m_axi_pmem_lsu_wdata     ),
    .m_axi_pmem_wstrb     (m_axi_pmem_lsu_wstrb     ),

    .s_axi_pmem_bvalid    (s_axi_pmem_lsu_bvalid    ),
    .m_axi_pmem_bready    (m_axi_pmem_lsu_bready    ),
    .s_axi_pmem_bresp     (s_axi_pmem_lsu_bresp     ),

    .m_axi_pmem_arvalid   (m_axi_pmem_lsu_arvalid   ),
    .s_axi_pmem_arready   (s_axi_pmem_lsu_arready   ),
    .m_axi_pmem_araddr    (m_axi_pmem_lsu_araddr    ),
    .m_axi_pmem_arprot    (m_axi_pmem_lsu_arprot    ),

    .s_axi_pmem_rvalid    (s_axi_pmem_lsu_rvalid    ),
    .m_axi_pmem_rready    (m_axi_pmem_lsu_rready    ),
    .s_axi_pmem_rdata     (s_axi_pmem_lsu_rdata     ),
    .s_axi_pmem_rresp     (s_axi_pmem_lsu_rresp     )
);

// output declaration of module ysyx_24120013_ECU
wire [ADDR_WIDTH-1:0] ecu_reg_waddr;
wire [DATA_WIDTH-1:0] ecu_reg_wdata;
wire ecu_jump_pc_flag;
wire [DATA_WIDTH-1:0] ecu_jump_pc;

ysyx_24120013_ECU #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) u_ysyx_24120013_ECU(
    .clk              	(clk               ),
    .rst              	(rst               ),
    .ecu_op           	(ecu_op            ),
    .ecu_pc           	(ecu_pc            ),
    .ecu_csr_waddr      (ecu_csr_waddr     ),
    .alu_csr_rdata    	(alu_result        ),
    .csr_rdata        	(csr_rdata         ),
    .ecu_reg_rdata      (ecu_reg_rdata     ),
    .ecu_reg_wdata    	(ecu_reg_wdata     ),
    .csr_wen            (ecu_csr_wen       ),
    .csr_waddr1       	(csr_waddr1        ),
    .csr_waddr2       	(csr_waddr2        ),
    .csr_waddr3       	(csr_waddr3        ),
    .csr_wdata1       	(csr_wdata1        ),
    .csr_wdata2       	(csr_wdata2        ),
    .csr_wdata3       	(csr_wdata3        ),
    .ecu_jump_pc_flag 	(ecu_jump_pc_flag  ),
    .ecu_jump_pc      	(ecu_jump_pc       )
);


endmodule