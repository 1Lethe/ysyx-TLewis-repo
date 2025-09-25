import "DPI-C" function void sim_pmem_write(input int waddr, input int wdata, input byte wmask);
import "DPI-C" function int sim_pmem_read(input int raddr);
import "DPI-C" function int sim_read_RTC(input int raddr);
import "DPI-C" function void sim_hardware_fault_handle(input int NO,input int arg0);

import "DPI-C" function void halt ();

`include "define/exu_command.v"

module ysyx_24120013_top (
    input clk,
    input rst,
    output reg [DATA_WIDTH-1:0] pc,

    /* display to C++ interface */
    output wire [DATA_WIDTH-1:0] rf_dis [2**ADDR_WIDTH-1:0],
    output wire [DATA_WIDTH-1:0] csr_mstatus_dis,
    output wire [DATA_WIDTH-1:0] csr_mtvec_dis,
    output wire [DATA_WIDTH-1:0] csr_mepc_dis,
    output wire [DATA_WIDTH-1:0] csr_mcause_dis,
    output reg difftest_check_flag,
    output wire [DATA_WIDTH-1:0] trap_flag
);

parameter MEM_WIDTH = 32;
parameter ADDR_WIDTH = 5;
parameter DATA_WIDTH = 32;

/* DEVICE MMIO CONFIG */
parameter PMEM_BASE = 32'h80000000;
parameter PMEM_SIZE =  32'h8000000;
parameter UART_MMIO_BASE = 32'ha00003f8;
parameter UART_MMIO_SIZE = 32'h8;
parameter CLINT_MMIO_BASE = 32'ha0000048;
parameter CLINT_MMIO_SIZE = 32'h8;

wire pc_jmp_en;
wire [DATA_WIDTH-1:0] branch_jmp_pc;

ysyx_24120013_PC #(
    .DATA_WIDTH(DATA_WIDTH)
)u_ysyx_24120013_PC(
    .clk        	(clk             ),
    .rst        	(rst             ),
    .pc_jmp_val 	(branch_jmp_pc   ),
    .pc         	(pc              ),
    .next_inst_flag (next_inst_flag  )
);

// output declaration of module ysyx_24120023_IFU
wire [DATA_WIDTH-1:0]inst;
wire inst_is_valid;

wire        m_axi_pmem_ifu_arvalid;
wire        s_axi_pmem_ifu_arready;
wire [MEM_WIDTH-1:0] m_axi_pmem_ifu_araddr;
wire [2:0]  m_axi_pmem_ifu_arprot;

wire        s_axi_pmem_ifu_rvalid;
wire        m_axi_pmem_ifu_rready;
wire [DATA_WIDTH-1:0] s_axi_pmem_ifu_rdata;
wire [1:0]  s_axi_pmem_ifu_rresp;

ysyx_24120023_IFU u_ysyx_24120023_IFU(
    .clk      	             (clk                       ),
    .rst      	             (rst                       ),
    .pc                      (pc                        ),
    .next_inst_flag          (next_inst_flag            ),
    .id_is_ready             (id_is_ready               ),
    .inst_is_valid           (inst_is_valid             ),
    .IFU_inst                (inst                      ),
    .m_axi_pmem_ifu_arvalid  (m_axi_pmem_ifu_arvalid    ),
    .s_axi_pmem_ifu_arready  (s_axi_pmem_ifu_arready    ),
    .m_axi_pmem_ifu_araddr   (m_axi_pmem_ifu_araddr     ),
    .m_axi_pmem_ifu_arprot   (m_axi_pmem_ifu_arprot     ),
    .s_axi_pmem_ifu_rvalid   (s_axi_pmem_ifu_rvalid     ),
    .m_axi_pmem_ifu_rready   (m_axi_pmem_ifu_rready     ),
    .s_axi_pmem_ifu_rdata    (s_axi_pmem_ifu_rdata      ),
    .s_axi_pmem_ifu_rresp    (s_axi_pmem_ifu_rresp      )
);

// output declaration of module ysyx_24120013_IDU
wire [ADDR_WIDTH-1:0] reg_raddr1;
wire [ADDR_WIDTH-1:0] reg_raddr2;
wire [`ysyx_24120013_CSR_ADDR_WIDTH-1:0] ecu_csr_waddr;
wire [DATA_WIDTH-1:0] ecu_pc;
wire [DATA_WIDTH-1:0] ecu_reg_rdata;
wire [DATA_WIDTH-1:0] alu_src1;
wire [DATA_WIDTH-1:0] alu_src2;
wire [ADDR_WIDTH-1:0] wr_reg_des;
wire [`ysyx_24120013_ALUOP_WIDTH-1:0] alu_op;
wire [DATA_WIDTH-1:0] branch_imm;
wire [DATA_WIDTH-1:0] branch_rs1;
wire [DATA_WIDTH-1:0] branch_pc;
wire [`ysyx_24120013_BRANCH_WIDTH-1:0] branch_op;
wire mem_valid;
wire mem_ren;
wire mem_wen;
wire [DATA_WIDTH-1:0] mem_wdata;
wire [7:0] mem_wtype;
wire [7:0] mem_rtype;
wire [`ysyx_24120013_ZERO_WIDTH-1:0] mem_zero_width;
wire [`ysyx_24120013_SEXT_WIDTH-1:0] mem_sext_width;
wire [`ysyx_24120013_ECU_WIDTH-1:0] ecu_op;
wire break_ctrl;
wire id_is_ready;
wire id_is_valid;

ysyx_24120013_IDU #(
    .MEM_WIDTH  (MEM_WIDTH ),
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
)u_ysyx_24120013_IDU(
    .clk         	(clk             ),
    .rst         	(rst             ),
    .inst        	(inst            ),
    .pc             (pc              ),
    .reg_rdata1     (reg_rdata1      ),
    .reg_rdata2     (reg_rdata2      ),
    .csr_rdata      (csr_rdata       ),
    .reg_raddr1  	(reg_raddr1      ),
    .reg_raddr2  	(reg_raddr2      ),
    .ecu_op         (ecu_op          ),
    .ecu_pc         (ecu_pc          ),
    .ecu_reg_rdata  (ecu_reg_rdata   ), 
    .csr_raddr      (csr_raddr       ),
    .ecu_csr_waddr  (ecu_csr_waddr   ),
    .alu_src1    	(alu_src1        ),
    .alu_src2    	(alu_src2        ),
    .alu_op         (alu_op          ),
    .branch_op      (branch_op       ),
    .branch_imm     (branch_imm      ),
    .branch_rs1     (branch_rs1      ),
    .branch_pc      (branch_pc       ),
    .mem_valid      (mem_valid       ),
    .mem_ren        (mem_ren         ),
    .mem_wen        (mem_wen         ),
    .mem_wdata      (mem_wdata       ),
    .mem_wtype      (mem_wtype       ),
    .mem_rtype      (mem_rtype       ),
    .mem_zero_width (mem_zero_width  ),
    .mem_sext_width (mem_sext_width  ),
    .wr_reg_des     (wr_reg_des      ),
    .break_ctrl     (break_ctrl      ),
    .inst_is_valid  (inst_is_valid   ),
    .id_is_ready    (id_is_ready     ),
    .ex_is_ready    (ex_is_ready     ),
    .id_is_valid    (id_is_valid     )
);

// output declaration of module ysyx_24120013_RegisterFile
wire [DATA_WIDTH-1:0] reg_rdata1;
wire [DATA_WIDTH-1:0] reg_rdata2;
wire [`ysyx_24120013_CSR_ADDR_WIDTH-1:0] csr_raddr;
wire [DATA_WIDTH-1:0] csr_rdata;
wire csr_wen;
wire [`ysyx_24120013_CSR_ADDR_WIDTH-1:0] csr_waddr1;
wire [DATA_WIDTH-1:0] csr_wdata1;
wire [`ysyx_24120013_CSR_ADDR_WIDTH-1:0] csr_waddr2;
wire [DATA_WIDTH-1:0] csr_wdata2;
wire [`ysyx_24120013_CSR_ADDR_WIDTH-1:0] csr_waddr3;
wire [DATA_WIDTH-1:0] csr_wdata3;
wire wb_is_ready;
wire next_inst_flag;

always @(posedge clk) begin
    if(rst)
        difftest_check_flag <= 1'b0;
    else
        difftest_check_flag <= next_inst_flag;
end

ysyx_24120013_RegisterFile #(
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
)u_ysyx_24120013_RegisterFile(
    .clk    	     (clk              ),
    .rst    	     (rst              ),
    .wdata  	     (reg_wdata        ),
    .waddr  	     (reg_waddr        ),
    .wen    	     (reg_wen          ),
    .raddr1 	     (reg_raddr1       ),
    .raddr2 	     (reg_raddr2       ),
    .rdata1 	     (reg_rdata1       ),
    .rdata2 	     (reg_rdata2       ),
    .csr_waddr1      (csr_waddr1       ),
    .csr_wdata1      (csr_wdata1       ),
    .csr_waddr2      (csr_waddr2       ),
    .csr_wdata2      (csr_wdata2       ),
    .csr_waddr3      (csr_waddr3       ),
    .csr_wdata3      (csr_wdata3       ),
    .csr_wen         (csr_wen          ), 
    .csr_raddr       (csr_raddr        ),
    .csr_rdata       (csr_rdata        ),
    .rf_dis          (rf_dis           ),
    .csr_mstatus_dis (csr_mstatus_dis  ),
    .csr_mtvec_dis   (csr_mtvec_dis    ),
    .csr_mepc_dis    (csr_mepc_dis     ),
    .csr_mcause_dis  (csr_mcause_dis   ),
    .trap_flag       (trap_flag        ),

    .ex_is_valid     (ex_is_valid      ),
    .wb_is_ready     (wb_is_ready      ),
    .next_inst_flag  (next_inst_flag   )
);

// output declaration of module ysyx_24120013_EXU
wire reg_wen;
wire [ADDR_WIDTH-1:0] reg_waddr;
wire [DATA_WIDTH-1:0] reg_wdata;
wire ex_is_ready;
wire ex_is_valid;
wire mem_access_flag;

wire        m_axi_pmem_lsu_awvalid;
wire        s_axi_pmem_lsu_awready;
wire [MEM_WIDTH-1:0] m_axi_pmem_lsu_awaddr;
wire [2:0]  m_axi_pmem_lsu_awprot;

wire        m_axi_pmem_lsu_wvalid;
wire        s_axi_pmem_lsu_wready;
wire [DATA_WIDTH-1:0] m_axi_pmem_lsu_wdata;
wire [7:0]  m_axi_pmem_lsu_wstrb;

wire        s_axi_pmem_lsu_bvalid;
wire        m_axi_pmem_lsu_bready;
wire [1:0]  s_axi_pmem_lsu_bresp;

wire        m_axi_pmem_lsu_arvalid;
wire        s_axi_pmem_lsu_arready;
wire [MEM_WIDTH-1:0] m_axi_pmem_lsu_araddr;
wire [2:0]  m_axi_pmem_lsu_arprot;

wire        s_axi_pmem_lsu_rvalid;
wire        m_axi_pmem_lsu_rready;
wire [DATA_WIDTH-1:0] s_axi_pmem_lsu_rdata;
wire [1:0]  s_axi_pmem_lsu_rresp;

ysyx_24120013_EXU #(
    .MEM_WIDTH (MEM_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
)u_ysyx_24120013_EXU(
    .clk       	    (clk           ),
    .rst       	    (rst           ),
    .alu_src1      	(alu_src1      ),
    .alu_src2      	(alu_src2      ),
    .alu_op         (alu_op        ),
    .branch_imm     (branch_imm    ),
    .branch_rs1     (branch_rs1    ),
    .branch_pc      (branch_pc     ),
    .branch_op      (branch_op     ),
    .mem_valid      (mem_valid     ),
    .mem_ren        (mem_ren       ),
    .mem_wen        (mem_wen       ),
    .mem_wdata      (mem_wdata     ),
    .mem_wtype      (mem_wtype     ),
    .mem_rtype      (mem_rtype     ),
    .mem_zero_width (mem_zero_width),
    .mem_sext_width (mem_sext_width),
    .mem_access_flag(mem_access_flag),
    .ecu_op         (ecu_op        ),
    .ecu_pc         (ecu_pc        ),
    .ecu_reg_rdata  (ecu_reg_rdata ),
    .ecu_csr_waddr  (ecu_csr_waddr ),
    .csr_rdata      (csr_rdata     ),
    .break_ctrl     (break_ctrl    ),
    .wr_reg_des     (wr_reg_des    ),
    .reg_wen   	    (reg_wen       ),
    .reg_waddr 	    (reg_waddr     ),
    .reg_wdata 	    (reg_wdata     ),
    .csr_wen        (csr_wen       ),
    .csr_waddr1     (csr_waddr1    ),
    .csr_wdata1     (csr_wdata1    ),
    .csr_waddr2     (csr_waddr2    ),
    .csr_wdata2     (csr_wdata2    ),
    .csr_waddr3     (csr_waddr3    ),
    .csr_wdata3     (csr_wdata3    ),
    .branch_jmp_pc  (branch_jmp_pc ),

    .id_is_valid     (id_is_valid  ),
    .ex_is_ready     (ex_is_ready  ),
    .wb_is_ready     (wb_is_ready  ),
    .ex_is_valid      (ex_is_valid  ),

    .m_axi_pmem_lsu_awvalid  (m_axi_pmem_lsu_awvalid),
    .s_axi_pmem_lsu_awready  (s_axi_pmem_lsu_awready),
    .m_axi_pmem_lsu_awaddr   (m_axi_pmem_lsu_awaddr),
    .m_axi_pmem_lsu_awprot   (m_axi_pmem_lsu_awprot),

    .m_axi_pmem_lsu_wvalid   (m_axi_pmem_lsu_wvalid),
    .s_axi_pmem_lsu_wready   (s_axi_pmem_lsu_wready),
    .m_axi_pmem_lsu_wdata    (m_axi_pmem_lsu_wdata),
    .m_axi_pmem_lsu_wstrb    (m_axi_pmem_lsu_wstrb),

    .s_axi_pmem_lsu_bvalid   (s_axi_pmem_lsu_bvalid),
    .m_axi_pmem_lsu_bready   (m_axi_pmem_lsu_bready),
    .s_axi_pmem_lsu_bresp    (s_axi_pmem_lsu_bresp),

    .m_axi_pmem_lsu_arvalid  (m_axi_pmem_lsu_arvalid),
    .s_axi_pmem_lsu_arready  (s_axi_pmem_lsu_arready),
    .m_axi_pmem_lsu_araddr   (m_axi_pmem_lsu_araddr),
    .m_axi_pmem_lsu_arprot   (m_axi_pmem_lsu_arprot),

    .s_axi_pmem_lsu_rvalid   (s_axi_pmem_lsu_rvalid),
    .m_axi_pmem_lsu_rready   (m_axi_pmem_lsu_rready),
    .s_axi_pmem_lsu_rdata    (s_axi_pmem_lsu_rdata),
    .s_axi_pmem_lsu_rresp    (s_axi_pmem_lsu_rresp)
);

// output declaration of module pmem_sim
wire        m_axi_pmem_awvalid;
wire        s_axi_pmem_awready;
wire [MEM_WIDTH-1:0] m_axi_pmem_awaddr;
wire [2:0]  m_axi_pmem_awprot;

wire        m_axi_pmem_wvalid;
wire        s_axi_pmem_wready;
wire [DATA_WIDTH-1:0] m_axi_pmem_wdata;
wire [7:0]  m_axi_pmem_wstrb;

wire        s_axi_pmem_bvalid;
wire        m_axi_pmem_bready;
wire [1:0]  s_axi_pmem_bresp;

wire        m_axi_pmem_arvalid;
wire        s_axi_pmem_arready;
wire [MEM_WIDTH-1:0] m_axi_pmem_araddr;
wire [2:0]  m_axi_pmem_arprot;

wire        s_axi_pmem_rvalid;
wire        m_axi_pmem_rready;
wire [DATA_WIDTH-1:0] s_axi_pmem_rdata;
wire [1:0]  s_axi_pmem_rresp;

pmem_sim #(
    .MEM_WIDTH (MEM_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
)u_pmem_sim(
    .aclk       (clk               ),
    .areset_n   (rst               ),
    .m_awvalid  (m_axi_pmem_awvalid),
    .s_awready  (s_axi_pmem_awready),
    .m_awaddr   (m_axi_pmem_awaddr ),
    .m_awprot   (m_axi_pmem_awprot ),
    .m_wvalid   (m_axi_pmem_wvalid ),
    .s_wready   (s_axi_pmem_wready ),
    .m_wdata    (m_axi_pmem_wdata  ),
    .m_wstrb    (m_axi_pmem_wstrb  ),
    .s_bvalid   (s_axi_pmem_bvalid ),
    .m_bready   (m_axi_pmem_bready ),
    .s_bresp    (s_axi_pmem_bresp  ),
    .m_arvalid  (m_axi_pmem_arvalid),
    .s_arready  (s_axi_pmem_arready),
    .m_araddr   (m_axi_pmem_araddr ),
    .m_arprot   (m_axi_pmem_arprot ),
    .s_rvalid   (s_axi_pmem_rvalid ),
    .m_rready   (m_axi_pmem_rready ),
    .s_rdata    (s_axi_pmem_rdata  ),
    .s_rresp    (s_axi_pmem_rresp  )
);


// output declaration of module ysyx_24120013_pmem_arbiter
wire        m_axi_uart_awvalid;
wire        s_axi_uart_awready;
wire [MEM_WIDTH-1:0] m_axi_uart_awaddr;
wire [2:0]  m_axi_uart_awprot;

wire        m_axi_uart_wvalid;
wire        s_axi_uart_wready;
wire [DATA_WIDTH-1:0] m_axi_uart_wdata;
wire [7:0]  m_axi_uart_wstrb;

wire        s_axi_uart_bvalid;
wire        m_axi_uart_bready;
wire [1:0]  s_axi_uart_bresp;

uart_sim #(
    .MEM_WIDTH(MEM_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) u_uart_sim (
    .aclk        (clk               ),
    .areset_n    (rst               ),
    .m_awvalid   (m_axi_uart_awvalid),
    .s_awready   (s_axi_uart_awready),
    .m_awaddr    (m_axi_uart_awaddr ),
    .m_awprot    (m_axi_uart_awprot ),
    .m_wvalid    (m_axi_uart_wvalid ),
    .s_wready    (s_axi_uart_wready ),
    .m_wdata     (m_axi_uart_wdata  ),
    .m_wstrb     (m_axi_uart_wstrb  ),
    .s_bvalid    (s_axi_uart_bvalid ),
    .m_bready    (m_axi_uart_bready ),
    .s_bresp     (s_axi_uart_bresp  )
);

// output declaration of module ysyx_24120013_clint
wire        m_axi_clint_arvalid;
wire        s_axi_clint_arready;
wire [MEM_WIDTH-1:0] m_axi_clint_araddr;
wire [2:0]  m_axi_clint_arprot;

wire        s_axi_clint_rvalid;
wire        m_axi_clint_rready;
wire [DATA_WIDTH-1:0] s_axi_clint_rdata;
wire [1:0]  s_axi_clint_rresp;

ysyx_24120013_CLINT #(
    .MEM_WIDTH 	(MEM_WIDTH),
    .DATA_WIDTH (DATA_WIDTH),
    .CLINT_MMIO_BASE   (CLINT_MMIO_BASE),
    .CLINT_MMIO_SIZE   (CLINT_MMIO_SIZE)
)u_ysyx_24120013_CLINT(
    .aclk               (clk                 ),
    .areset_n           (rst                 ),
    .m_arvalid          (m_axi_clint_arvalid ),
    .s_arready          (s_axi_clint_arready ),
    .m_araddr           (m_axi_clint_araddr  ),
    .m_arprot           (m_axi_clint_arprot  ),
    .s_rvalid           (s_axi_clint_rvalid  ),
    .m_rready           (m_axi_clint_rready  ),
    .s_rdata            (s_axi_clint_rdata   ),
    .s_rresp            (s_axi_clint_rresp   )
);


ysyx_24120013_pmem_arbiter #(
    .MEM_WIDTH        (MEM_WIDTH),
    .DATA_WIDTH       (DATA_WIDTH),
    .PMEM_BASE        (PMEM_BASE),
    .PMEM_SIZE        (PMEM_SIZE),
    .UART_MMIO_BASE   (UART_MMIO_BASE),
    .UART_MMIO_SIZE   (UART_MMIO_SIZE),
    .CLINT_MMIO_BASE  (CLINT_MMIO_BASE),
    .CLINT_MMIO_SIZE  (CLINT_MMIO_SIZE)
)u_ysyx_24120013_pmem_arbiter( 
    .aclk                   	(clk                     ),
    .areset_n               	(rst                     ),

    .m_axi_pmem_lsu_awvalid 	(m_axi_pmem_lsu_awvalid  ),
    .s_axi_pmem_lsu_awready 	(s_axi_pmem_lsu_awready  ),
    .m_axi_pmem_lsu_awaddr  	(m_axi_pmem_lsu_awaddr   ),
    .m_axi_pmem_lsu_awprot  	(m_axi_pmem_lsu_awprot   ),
    .m_axi_pmem_lsu_wvalid  	(m_axi_pmem_lsu_wvalid   ),
    .s_axi_pmem_lsu_wready  	(s_axi_pmem_lsu_wready   ),
    .m_axi_pmem_lsu_wdata   	(m_axi_pmem_lsu_wdata    ),
    .m_axi_pmem_lsu_wstrb   	(m_axi_pmem_lsu_wstrb    ),
    .s_axi_pmem_lsu_bvalid  	(s_axi_pmem_lsu_bvalid   ),
    .m_axi_pmem_lsu_bready  	(m_axi_pmem_lsu_bready   ),
    .s_axi_pmem_lsu_bresp   	(s_axi_pmem_lsu_bresp    ),
    .m_axi_pmem_lsu_arvalid 	(m_axi_pmem_lsu_arvalid  ),
    .s_axi_pmem_lsu_arready 	(s_axi_pmem_lsu_arready  ),
    .m_axi_pmem_lsu_araddr  	(m_axi_pmem_lsu_araddr   ),
    .m_axi_pmem_lsu_arprot  	(m_axi_pmem_lsu_arprot   ),
    .s_axi_pmem_lsu_rvalid  	(s_axi_pmem_lsu_rvalid   ),
    .m_axi_pmem_lsu_rready  	(m_axi_pmem_lsu_rready   ),
    .s_axi_pmem_lsu_rdata   	(s_axi_pmem_lsu_rdata    ),
    .s_axi_pmem_lsu_rresp   	(s_axi_pmem_lsu_rresp    ),

    .m_axi_pmem_ifu_arvalid 	(m_axi_pmem_ifu_arvalid  ),
    .s_axi_pmem_ifu_arready 	(s_axi_pmem_ifu_arready  ),
    .m_axi_pmem_ifu_araddr  	(m_axi_pmem_ifu_araddr   ),
    .m_axi_pmem_ifu_arprot  	(m_axi_pmem_ifu_arprot   ),
    .s_axi_pmem_ifu_rvalid  	(s_axi_pmem_ifu_rvalid   ),
    .m_axi_pmem_ifu_rready  	(m_axi_pmem_ifu_rready   ),
    .s_axi_pmem_ifu_rdata   	(s_axi_pmem_ifu_rdata    ),
    .s_axi_pmem_ifu_rresp   	(s_axi_pmem_ifu_rresp    ),

    .m_axi_pmem_awvalid     	(m_axi_pmem_awvalid      ),
    .s_axi_pmem_awready     	(s_axi_pmem_awready      ),
    .m_axi_pmem_awaddr      	(m_axi_pmem_awaddr       ),
    .m_axi_pmem_awprot      	(m_axi_pmem_awprot       ),
    .m_axi_pmem_wvalid      	(m_axi_pmem_wvalid       ),
    .s_axi_pmem_wready      	(s_axi_pmem_wready       ),
    .m_axi_pmem_wdata       	(m_axi_pmem_wdata        ),
    .m_axi_pmem_wstrb       	(m_axi_pmem_wstrb        ),
    .s_axi_pmem_bvalid      	(s_axi_pmem_bvalid       ),
    .m_axi_pmem_bready      	(m_axi_pmem_bready       ),
    .s_axi_pmem_bresp       	(s_axi_pmem_bresp        ),
    .m_axi_pmem_arvalid     	(m_axi_pmem_arvalid      ),
    .s_axi_pmem_arready     	(s_axi_pmem_arready      ),
    .m_axi_pmem_araddr      	(m_axi_pmem_araddr       ),
    .m_axi_pmem_arprot      	(m_axi_pmem_arprot       ),
    .s_axi_pmem_rvalid      	(s_axi_pmem_rvalid       ),
    .m_axi_pmem_rready      	(m_axi_pmem_rready       ),
    .s_axi_pmem_rdata       	(s_axi_pmem_rdata        ),
    .s_axi_pmem_rresp       	(s_axi_pmem_rresp        ),

    .m_axi_uart_awvalid     	(m_axi_uart_awvalid      ),
    .s_axi_uart_awready     	(s_axi_uart_awready      ),
    .m_axi_uart_awaddr      	(m_axi_uart_awaddr       ),
    .m_axi_uart_awprot      	(m_axi_uart_awprot       ),
    .m_axi_uart_wvalid      	(m_axi_uart_wvalid       ),
    .s_axi_uart_wready      	(s_axi_uart_wready       ),
    .m_axi_uart_wdata       	(m_axi_uart_wdata        ),
    .m_axi_uart_wstrb       	(m_axi_uart_wstrb        ),
    .s_axi_uart_bvalid      	(s_axi_uart_bvalid       ),
    .m_axi_uart_bready      	(m_axi_uart_bready       ),
    .s_axi_uart_bresp       	(s_axi_uart_bresp        ),

    .m_axi_clint_arvalid        (m_axi_clint_arvalid    ),
    .s_axi_clint_arready        (s_axi_clint_arready    ),
    .m_axi_clint_araddr         (m_axi_clint_araddr     ),
    .m_axi_clint_arprot         (m_axi_clint_arprot     ),
    .s_axi_clint_rvalid         (s_axi_clint_rvalid     ),
    .m_axi_clint_rready         (m_axi_clint_rready     ),
    .s_axi_clint_rdata          (s_axi_clint_rdata      ),
    .s_axi_clint_rresp          (s_axi_clint_rresp      ),

    .inst_fetch_flag            (next_inst_flag         ),
    .mem_access_flag            (mem_access_flag        )
);

endmodule
