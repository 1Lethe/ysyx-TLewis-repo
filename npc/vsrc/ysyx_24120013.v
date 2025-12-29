import "DPI-C" function void sim_pmem_write(input int waddr, input int wdata, input byte wmask);
import "DPI-C" function int sim_pmem_read(input int raddr);
import "DPI-C" function int sim_read_RTC(input int raddr);
import "DPI-C" function void sim_hardware_fault_handle(input int NO,input int arg0);

import "DPI-C" function void halt ();

`include "cpu_defines.v"

module ysyx_24120013 (
    input clock,
    input reset,
    input io_interrupt,

    input  wire                     io_master_awready,
    output wire                     io_master_awvalid,
    output wire [MEM_WIDTH-1:0]     io_master_awaddr,
    output wire [3:0]               io_master_awid,
    output wire [7:0]               io_master_awlen,
    output wire [2:0]               io_master_awsize,
    output wire [1:0]               io_master_awburst,

    input  wire                     io_master_wready,
    output wire                     io_master_wvalid,
    output wire [DATA_WIDTH-1:0]    io_master_wdata,
    output wire [3:0]               io_master_wstrb,
    output wire                     io_master_wlast,

    output wire                     io_master_bready,
    input  wire                     io_master_bvalid,
    input  wire [1:0]               io_master_bresp,
    input  wire [3:0]               io_master_bid,

    input  wire                     io_master_arready,
    output wire                     io_master_arvalid,
    output wire [MEM_WIDTH-1:0]     io_master_araddr,
    output wire [3:0]               io_master_arid,
    output wire [7:0]               io_master_arlen,
    output wire [2:0]               io_master_arsize,
    output wire [1:0]               io_master_arburst,

    output wire                     io_master_rready,
    input  wire                     io_master_rvalid,
    input  wire [1:0]               io_master_rresp,
    input  wire [DATA_WIDTH-1:0]    io_master_rdata,
    input  wire                     io_master_rlast,
    input  wire [3:0]               io_master_rid,

    output wire                     io_slave_awready,
    input  wire                     io_slave_awvalid,
    input  wire [MEM_WIDTH-1:0]     io_slave_awaddr,
    input  wire [3:0]               io_slave_awid,
    input  wire [7:0]               io_slave_awlen,
    input  wire [2:0]               io_slave_awsize,
    input  wire [1:0]               io_slave_awburst,

    output wire                     io_slave_wready,
    input  wire                     io_slave_wvalid,
    input  wire [DATA_WIDTH-1:0]    io_slave_wdata,
    input  wire [3:0]               io_slave_wstrb,
    input  wire                     io_slave_wlast,

    input  wire                     io_slave_bready,
    output wire                     io_slave_bvalid,
    output wire [1:0]               io_slave_bresp,
    output wire [3:0]               io_slave_bid,

    output wire                     io_slave_arready,
    input  wire                     io_slave_arvalid,
    input  wire [MEM_WIDTH-1:0]     io_slave_araddr,
    input  wire [3:0]               io_slave_arid,
    input  wire [7:0]               io_slave_arlen,
    input  wire [2:0]               io_slave_arsize,
    input  wire [1:0]               io_slave_arburst,

    input  wire                     io_slave_rready,
    output wire                     io_slave_rvalid,
    output wire [1:0]               io_slave_rresp,
    output wire [DATA_WIDTH-1:0]    io_slave_rdata,
    output wire                     io_slave_rlast,
    output wire [3:0]               io_slave_rid
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

`ifdef ysyx_24120013_USE_CPP_SIM_ENV
/* For C++ SIM ENV */
wire [DATA_WIDTH-1:0] rf_difftest [2**ADDR_WIDTH-1:0];
wire [DATA_WIDTH-1:0] mstatus_difftest;
wire [DATA_WIDTH-1:0] mtvec_difftest;
wire [DATA_WIDTH-1:0] mepc_difftest;
wire [DATA_WIDTH-1:0] mcause_difftest;
wire [DATA_WIDTH-1:0] pc_difftest;

wire [DATA_WIDTH-1:0] csr_difftest [3:0];

reg difftest_check_flag;

assign csr_difftest[0] = mstatus_difftest;
assign csr_difftest[1] = mtvec_difftest;
assign csr_difftest[2] = mepc_difftest;
assign csr_difftest[3] = mcause_difftest;

assign pc_difftest = pc;

always @(posedge clock) begin
    if(reset)
        difftest_check_flag <= 1'b0;
    else
        difftest_check_flag <= next_inst_flag;
end

export "DPI-C" function get_rf_value;
export "DPI-C" function get_csr_value;
export "DPI-C" function get_pc_value;
export "DPI-C" function is_check_difftest;

function int get_rf_value(int idx);
    return rf_difftest[idx];
endfunction

function int get_csr_value(int idx);
    return csr_difftest[idx];
endfunction

function int get_pc_value();
    return pc_difftest;
endfunction

function logic is_check_difftest();
    return difftest_check_flag;
endfunction

`endif

wire pc_jmp_en;
wire [DATA_WIDTH-1:0] pc;
wire [DATA_WIDTH-1:0] branch_jmp_pc;

ysyx_24120013_PC #(
    .DATA_WIDTH(DATA_WIDTH)
)u_ysyx_24120013_PC(
    .clk        	  (clock         ),
    .rst        	  (reset         ),
    .pc_jmp_val 	  (branch_jmp_pc ),
    .pc         	  (pc            ),
    .next_inst_flag   (next_inst_flag)
);

// output declaration of module ysyx_24120023_IFU
wire [DATA_WIDTH-1:0]inst;
wire inst_is_valid;

wire        simplebus_ifu_mem_rd_req;
wire [MEM_WIDTH-1:0] simplebus_ifu_mem_rd_addr;
wire [2:0]  simplebus_ifu_mem_rd_prot;
wire [DATA_WIDTH-1:0] simplebus_ifu_mem_rd_data;
wire [1:0]  simplebus_ifu_mem_rd_resp;
wire        simplebus_ifu_mem_rd_complete;

ysyx_24120013_IFU #(
    .MEM_WIDTH  (MEM_WIDTH ),
    .DATA_WIDTH (DATA_WIDTH)
) u_ysyx_24120013_IFU(
    .clk      	                  (clock                    ),
    .rst      	                  (reset                    ),
    .pc                           (pc                       ),
    .next_inst_flag               (next_inst_flag           ),
    .id_is_ready                  (id_is_ready              ),
    .inst_is_valid                (inst_is_valid            ),
    .IFU_inst                     (inst                     ),

    .simplebus_ifu_mem_rd_req     (simplebus_ifu_mem_rd_req     ),
    .simplebus_ifu_mem_rd_addr    (simplebus_ifu_mem_rd_addr    ),
    .simplebus_ifu_mem_rd_prot    (simplebus_ifu_mem_rd_prot    ),
    .simplebus_ifu_mem_rd_data    (simplebus_ifu_mem_rd_data    ),
    .simplebus_ifu_mem_rd_resp    (simplebus_ifu_mem_rd_resp    ),
    .simplebus_ifu_mem_rd_complete(simplebus_ifu_mem_rd_complete)
);

// output declaration of module ysyx_24120013_simplebus2axi4lite
wire        m_axi_ifu_mem_arvalid;
wire        s_axi_ifu_mem_arready; 
wire [MEM_WIDTH-1:0] m_axi_ifu_mem_araddr;
wire [2:0]  m_axi_ifu_mem_arprot;

wire        s_axi_ifu_mem_rvalid;
wire        m_axi_ifu_mem_rready;
wire [DATA_WIDTH-1:0] s_axi_ifu_mem_rdata;
wire [1:0]  s_axi_ifu_mem_rresp;

ysyx_24120013_simplebus2axi4lite #(
    .MEM_WIDTH  (MEM_WIDTH ),
    .DATA_WIDTH (DATA_WIDTH)
) u_ysyx_24120013_simplebus2axi4lite_ifu2axibridge(
    .clk                  ( clock                        ) ,
    .rst                  ( reset                        ) ,

    .simplebus_wr_req     ( 1'b0                         ) ,
    .simplebus_wr_addr    ( {MEM_WIDTH{1'b0}}            ) ,
    .simplebus_wr_data    ( {DATA_WIDTH{1'b0}}           ) ,
    .simplebus_wr_mask    ( 4'b0000                      ) ,
    .simplebus_wr_prot    ( 3'b000                       ) ,
    .simplebus_wr_resp    (                              ) ,
    .simplebus_wr_complete(                              ) ,

    .simplebus_rd_req     ( simplebus_ifu_mem_rd_req     ) ,
    .simplebus_rd_addr    ( simplebus_ifu_mem_rd_addr    ) ,
    .simplebus_rd_prot    ( simplebus_ifu_mem_rd_prot    ) ,
    .simplebus_rd_data    ( simplebus_ifu_mem_rd_data    ) ,
    .simplebus_rd_resp    ( simplebus_ifu_mem_rd_resp    ) ,
    .simplebus_rd_complete( simplebus_ifu_mem_rd_complete) ,

    .m_axi_awvalid        (                              ) ,
    .s_axi_awready        ( 1'b0                         ) ,
    .m_axi_awaddr         (                              ) ,
    .m_axi_awprot         (                              ) ,

    .m_axi_wvalid         (                              ) ,
    .s_axi_wready         ( 1'b0                         ) ,
    .m_axi_wdata          (                              ) ,
    .m_axi_wstrb          (                              ) ,

    .s_axi_bvalid         ( 1'b0                         ) ,
    .m_axi_bready         (                              ) ,
    .s_axi_bresp          ( 2'b00                        ) ,

    .m_axi_arvalid        ( m_axi_ifu_mem_arvalid        ) ,
    .s_axi_arready        ( s_axi_ifu_mem_arready        ) ,
    .m_axi_araddr         ( m_axi_ifu_mem_araddr         ) ,
    .m_axi_arprot         ( m_axi_ifu_mem_arprot         ) ,

    .s_axi_rvalid         ( s_axi_ifu_mem_rvalid         ) ,
    .m_axi_rready         ( m_axi_ifu_mem_rready         ) ,
    .s_axi_rdata          ( s_axi_ifu_mem_rdata          ) ,
    .s_axi_rresp          ( s_axi_ifu_mem_rresp          ) 
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
    .clk         	(clock           ),
    .rst         	(reset           ),
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

ysyx_24120013_RegisterFile #(
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
)u_ysyx_24120013_RegisterFile(
    .clk    	     (clock           ),
    .rst    	     (reset           ),
    .wdata           (reg_wdata       ),
    .waddr  	     (reg_waddr       ),
    .wen             (reg_wen         ),
    .raddr1 	     (reg_raddr1      ),
    .raddr2 	     (reg_raddr2      ),
    .rdata1          (reg_rdata1      ),
    .rdata2 	     (reg_rdata2      ),
    .csr_waddr1      (csr_waddr1      ),
    .csr_wdata1      (csr_wdata1      ),
    .csr_waddr2      (csr_waddr2      ),
    .csr_wdata2      (csr_wdata2      ),
    .csr_waddr3      (csr_waddr3      ),
    .csr_wdata3      (csr_wdata3      ),
    .csr_wen         (csr_wen         ), 
    .csr_raddr       (csr_raddr       ),
    .csr_rdata       (csr_rdata       ),
`ifdef ysyx_24120013_USE_CPP_SIM_ENV
    .rf_difftest     (rf_difftest     ),
    .mstatus_difftest(mstatus_difftest),
    .mtvec_difftest  (mtvec_difftest  ),
    .mepc_difftest   (mepc_difftest   ),
    .mcause_difftest (mcause_difftest ),
`endif
    .ex_is_valid     (ex_is_valid     ),
    .wb_is_ready     (wb_is_ready     ),
    .next_inst_flag  (next_inst_flag  )
);

// output declaration of module ysyx_24120013_EXU
wire reg_wen;
wire [ADDR_WIDTH-1:0] reg_waddr;
wire [DATA_WIDTH-1:0] reg_wdata;
wire ex_is_ready;
wire ex_is_valid;
wire mem_access_flag;

wire        simplebus_lsu_mem_wr_req;
wire [MEM_WIDTH-1:0] simplebus_lsu_mem_wr_addr;
wire [DATA_WIDTH-1:0] simplebus_lsu_mem_wr_data;
wire [3:0]  simplebus_lsu_mem_wr_mask;
wire [2:0]  simplebus_lsu_mem_wr_prot;
wire [1:0]  simplebus_lsu_mem_wr_resp;
wire        simplebus_lsu_mem_wr_complete;

wire        simplebus_lsu_mem_rd_req;
wire [MEM_WIDTH-1:0] simplebus_lsu_mem_rd_addr;
wire [2:0]  simplebus_lsu_mem_rd_prot;
wire [DATA_WIDTH-1:0] simplebus_lsu_mem_rd_data;
wire [1:0]  simplebus_lsu_mem_rd_resp;
wire        simplebus_lsu_mem_rd_complete;

ysyx_24120013_EXU #(
    .MEM_WIDTH (MEM_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
)u_ysyx_24120013_EXU(
    .clk       	    (clock         ),
    .rst       	    (reset         ),
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
    .ex_is_valid     (ex_is_valid  ),

    .simplebus_lsu_mem_wr_req       (simplebus_lsu_mem_wr_req       ),
    .simplebus_lsu_mem_wr_addr      (simplebus_lsu_mem_wr_addr      ),
    .simplebus_lsu_mem_wr_data      (simplebus_lsu_mem_wr_data      ),
    .simplebus_lsu_mem_wr_mask      (simplebus_lsu_mem_wr_mask      ),
    .simplebus_lsu_mem_wr_prot      (simplebus_lsu_mem_wr_prot      ),
    .simplebus_lsu_mem_wr_resp      (simplebus_lsu_mem_wr_resp      ),
    .simplebus_lsu_mem_wr_complete  (simplebus_lsu_mem_wr_complete  ),

    .simplebus_lsu_mem_rd_req       (simplebus_lsu_mem_rd_req       ),
    .simplebus_lsu_mem_rd_addr      (simplebus_lsu_mem_rd_addr      ),
    .simplebus_lsu_mem_rd_prot      (simplebus_lsu_mem_rd_prot      ),
    .simplebus_lsu_mem_rd_data      (simplebus_lsu_mem_rd_data      ),
    .simplebus_lsu_mem_rd_resp      (simplebus_lsu_mem_rd_resp      ),
    .simplebus_lsu_mem_rd_complete  (simplebus_lsu_mem_rd_complete  )
);

// output declaration of module ysyx_24120013_simplebus2axi4lite
wire        m_axi_lsu_mem_awvalid;
wire        s_axi_lsu_mem_awready;
wire [MEM_WIDTH-1:0] m_axi_lsu_mem_awaddr;
wire [2:0]  m_axi_lsu_mem_awprot;

wire        m_axi_lsu_mem_wvalid;
wire        s_axi_lsu_mem_wready;
wire [DATA_WIDTH-1:0] m_axi_lsu_mem_wdata;
wire [3:0]  m_axi_lsu_mem_wstrb;

wire        s_axi_lsu_mem_bvalid;
wire        m_axi_lsu_mem_bready;
wire [1:0]  s_axi_lsu_mem_bresp;

wire        m_axi_lsu_mem_arvalid;
wire        s_axi_lsu_mem_arready;
wire [MEM_WIDTH-1:0] m_axi_lsu_mem_araddr;
wire [2:0]  m_axi_lsu_mem_arprot;

wire        s_axi_lsu_mem_rvalid;
wire        m_axi_lsu_mem_rready;
wire [DATA_WIDTH-1:0] s_axi_lsu_mem_rdata;
wire [1:0]  s_axi_lsu_mem_rresp;

ysyx_24120013_simplebus2axi4lite #(
    .MEM_WIDTH (MEM_WIDTH),
    .DATA_WIDTH (DATA_WIDTH)
) u_ysyx_24120013_simplebus2axi4lite_lsu2axibridge(
    .clk                  (clock                        ),
    .rst                  (reset                        ),

    .simplebus_wr_req     (simplebus_lsu_mem_wr_req     ),
    .simplebus_wr_addr    (simplebus_lsu_mem_wr_addr    ),
    .simplebus_wr_data    (simplebus_lsu_mem_wr_data    ),
    .simplebus_wr_mask    (simplebus_lsu_mem_wr_mask    ),
    .simplebus_wr_prot    (simplebus_lsu_mem_wr_prot    ),
    .simplebus_wr_resp    (simplebus_lsu_mem_wr_resp    ),
    .simplebus_wr_complete(simplebus_lsu_mem_wr_complete),

    .simplebus_rd_req     (simplebus_lsu_mem_rd_req     ),
    .simplebus_rd_addr    (simplebus_lsu_mem_rd_addr    ),
    .simplebus_rd_prot    (simplebus_lsu_mem_rd_prot    ),
    .simplebus_rd_data    (simplebus_lsu_mem_rd_data    ),
    .simplebus_rd_resp    (simplebus_lsu_mem_rd_resp    ),
    .simplebus_rd_complete(simplebus_lsu_mem_rd_complete),

    .m_axi_awvalid        (m_axi_lsu_mem_awvalid        ),
    .s_axi_awready        (s_axi_lsu_mem_awready        ),
    .m_axi_awaddr         (m_axi_lsu_mem_awaddr         ),
    .m_axi_awprot         (m_axi_lsu_mem_awprot         ),

    .m_axi_wvalid         (m_axi_lsu_mem_wvalid         ),
    .s_axi_wready         (s_axi_lsu_mem_wready         ),
    .m_axi_wdata          (m_axi_lsu_mem_wdata          ),
    .m_axi_wstrb          (m_axi_lsu_mem_wstrb          ),

    .s_axi_bvalid         (s_axi_lsu_mem_bvalid         ),
    .m_axi_bready         (m_axi_lsu_mem_bready         ),
    .s_axi_bresp          (s_axi_lsu_mem_bresp          ),

    .m_axi_arvalid        (m_axi_lsu_mem_arvalid        ),
    .s_axi_arready        (s_axi_lsu_mem_arready        ),
    .m_axi_araddr         (m_axi_lsu_mem_araddr         ),
    .m_axi_arprot         (m_axi_lsu_mem_arprot         ),

    .s_axi_rvalid         (s_axi_lsu_mem_rvalid         ),
    .m_axi_rready         (m_axi_lsu_mem_rready         ),
    .s_axi_rdata          (s_axi_lsu_mem_rdata          ),
    .s_axi_rresp          (s_axi_lsu_mem_rresp          )
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
    .aclk     (clock              ),
    .areset_n (reset              ),
    .m_arvalid(m_axi_clint_arvalid),
    .s_arready(s_axi_clint_arready),
    .m_araddr (m_axi_clint_araddr ),
    .m_arprot (m_axi_clint_arprot ),
    .s_rvalid (s_axi_clint_rvalid ),
    .m_rready (m_axi_clint_rready ),
    .s_rdata  (s_axi_clint_rdata  ),
    .s_rresp  (s_axi_clint_rresp  )
);

ysyx_24120013_axi_bridge #(
    .MEM_WIDTH      (MEM_WIDTH      ),
    .DATA_WIDTH     (DATA_WIDTH     ),
    .PMEM_BASE      (PMEM_BASE      ),
    .PMEM_SIZE      (PMEM_SIZE      ),
    .UART_MMIO_BASE (UART_MMIO_BASE ),
    .UART_MMIO_SIZE (UART_MMIO_SIZE ),
    .CLINT_MMIO_BASE(CLINT_MMIO_BASE),
    .CLINT_MMIO_SIZE(CLINT_MMIO_SIZE)
)u_ysyx_24120013_axi_bridge(
    .aclk                 (clock                  ),
    .areset               (reset                  ),

    /* master 1 (lsu) AXI4-Lite bus interface */
    .m_axi_lsu_mem_awvalid(m_axi_lsu_mem_awvalid  ),
    .s_axi_lsu_mem_awready(s_axi_lsu_mem_awready  ),
    .m_axi_lsu_mem_awaddr (m_axi_lsu_mem_awaddr   ),
    .m_axi_lsu_mem_awprot (m_axi_lsu_mem_awprot   ),

    .m_axi_lsu_mem_wvalid (m_axi_lsu_mem_wvalid   ),
    .s_axi_lsu_mem_wready (s_axi_lsu_mem_wready   ),
    .m_axi_lsu_mem_wdata  (m_axi_lsu_mem_wdata    ),
    .m_axi_lsu_mem_wstrb  (m_axi_lsu_mem_wstrb    ),

    .s_axi_lsu_mem_bvalid (s_axi_lsu_mem_bvalid   ),
    .m_axi_lsu_mem_bready (m_axi_lsu_mem_bready   ),
    .s_axi_lsu_mem_bresp  (s_axi_lsu_mem_bresp    ),

    .m_axi_lsu_mem_arvalid(m_axi_lsu_mem_arvalid  ),
    .s_axi_lsu_mem_arready(s_axi_lsu_mem_arready  ),
    .m_axi_lsu_mem_araddr (m_axi_lsu_mem_araddr   ),
    .m_axi_lsu_mem_arprot (m_axi_lsu_mem_arprot   ),

    .s_axi_lsu_mem_rvalid (s_axi_lsu_mem_rvalid   ),
    .m_axi_lsu_mem_rready (m_axi_lsu_mem_rready   ),
    .s_axi_lsu_mem_rdata  (s_axi_lsu_mem_rdata    ),
    .s_axi_lsu_mem_rresp  (s_axi_lsu_mem_rresp    ),

    /* master 2 (ifu) AXI4-Lite bus interface */
    .m_axi_ifu_mem_arvalid(m_axi_ifu_mem_arvalid  ),
    .s_axi_ifu_mem_arready(s_axi_ifu_mem_arready  ),
    .m_axi_ifu_mem_araddr (m_axi_ifu_mem_araddr   ),
    .m_axi_ifu_mem_arprot (m_axi_ifu_mem_arprot   ),

    .s_axi_ifu_mem_rvalid (s_axi_ifu_mem_rvalid   ),
    .m_axi_ifu_mem_rready (m_axi_ifu_mem_rready   ),
    .s_axi_ifu_mem_rdata  (s_axi_ifu_mem_rdata    ),
    .s_axi_ifu_mem_rresp  (s_axi_ifu_mem_rresp    ),

    /* slave 1 (ysyxSoC) AXI4 bus interface */
    .io_master_awvalid    (io_master_awvalid      ),
    .io_master_awready    (io_master_awready      ),
    .io_master_awaddr     (io_master_awaddr       ),
    .io_master_awid       (io_master_awid         ),
    .io_master_awlen      (io_master_awlen        ),
    .io_master_awsize     (io_master_awsize       ),
    .io_master_awburst    (io_master_awburst      ),
    .io_master_awprot     (/* UNUSED in ysyxSoC */), 

    .io_master_wready     (io_master_wready       ),
    .io_master_wvalid     (io_master_wvalid       ),
    .io_master_wdata      (io_master_wdata        ),
    .io_master_wstrb      (io_master_wstrb        ),
    .io_master_wlast      (io_master_wlast        ),

    .io_master_bready     (io_master_bready       ),
    .io_master_bvalid     (io_master_bvalid       ),
    .io_master_bresp      (io_master_bresp        ),
    .io_master_bid        (io_master_bid          ),

    .io_master_arready    (io_master_arready      ),
    .io_master_arvalid    (io_master_arvalid      ),
    .io_master_araddr     (io_master_araddr       ),
    .io_master_arid       (io_master_arid         ),
    .io_master_arlen      (io_master_arlen        ),
    .io_master_arsize     (io_master_arsize       ),
    .io_master_arburst    (io_master_arburst      ),
    .io_master_arprot     (/* UNUSED in ysyxSoC */),

    .io_master_rready     (io_master_rready       ),
    .io_master_rvalid     (io_master_rvalid       ),
    .io_master_rresp      (io_master_rresp        ),
    .io_master_rdata      (io_master_rdata        ),
    .io_master_rlast      (io_master_rlast        ),
    .io_master_rid        (io_master_rid          ),

    /* slave 2 (CLINT) AXI4-lite bus interface */
    .m_axi_clint_arvalid  (m_axi_clint_arvalid    ),
    .s_axi_clint_arready  (s_axi_clint_arready    ),
    .m_axi_clint_araddr   (m_axi_clint_araddr     ),
    .m_axi_clint_arprot   (m_axi_clint_arprot     ),

    .s_axi_clint_rvalid   (s_axi_clint_rvalid     ),
    .m_axi_clint_rready   (m_axi_clint_rready     ),
    .s_axi_clint_rdata    (s_axi_clint_rdata      ),
    .s_axi_clint_rresp    (s_axi_clint_rresp      ),

    .inst_fetch_flag      (next_inst_flag         ),
    .mem_access_flag      (mem_access_flag        )
);

endmodule
