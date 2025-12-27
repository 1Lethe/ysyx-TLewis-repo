module ysyx_24120013_axi_bridge
    #(
        MEM_WIDTH = 32, 
        DATA_WIDTH = 32,

        PMEM_BASE = 32'h80000000,
        PMEM_SIZE =  32'h8000000,
        UART_MMIO_BASE = 32'ha00003f8,
        UART_MMIO_SIZE = 32'h8,
        CLINT_MMIO_BASE = 32'ha0000048,
        CLINT_MMIO_SIZE = 32'h8
      )(
        input aclk,
        input areset,

        /* master 1 (lsu) AXI4-Lite bus interface */
        input  wire        m_axi_lsu_mem_awvalid,
        output wire        s_axi_lsu_mem_awready,
        input  wire [MEM_WIDTH-1:0] m_axi_lsu_mem_awaddr,
        input  wire [2:0]  m_axi_lsu_mem_awprot,

        input  wire        m_axi_lsu_mem_wvalid,
        output wire        s_axi_lsu_mem_wready,
        input  wire [DATA_WIDTH-1:0] m_axi_lsu_mem_wdata,
        input  wire [3:0]  m_axi_lsu_mem_wstrb,

        output wire        s_axi_lsu_mem_bvalid,
        input  wire        m_axi_lsu_mem_bready,
        output wire [1:0]  s_axi_lsu_mem_bresp,

        input  wire        m_axi_lsu_mem_arvalid,
        output wire        s_axi_lsu_mem_arready,
        input  wire [MEM_WIDTH-1:0] m_axi_lsu_mem_araddr,
        input  wire [2:0]  m_axi_lsu_mem_arprot,

        output wire        s_axi_lsu_mem_rvalid,
        input  wire        m_axi_lsu_mem_rready,
        output wire [DATA_WIDTH-1:0] s_axi_lsu_mem_rdata,
        output wire [1:0]  s_axi_lsu_mem_rresp,

        /* master 2 (ifu) AXI4-Lite bus interface */
        input  wire        m_axi_ifu_mem_arvalid,
        output wire        s_axi_ifu_mem_arready,
        input  wire [MEM_WIDTH-1:0] m_axi_ifu_mem_araddr,
        input  wire [2:0]  m_axi_ifu_mem_arprot,

        output wire        s_axi_ifu_mem_rvalid,
        input  wire        m_axi_ifu_mem_rready,
        output wire [DATA_WIDTH-1:0] s_axi_ifu_mem_rdata,
        output wire [1:0]  s_axi_ifu_mem_rresp,

        /* slave 1 (SoC) AXI4-Lite bus interface */
        output wire                     io_master_awvalid,
        input  wire                     io_master_awready,
        output wire [MEM_WIDTH-1:0]     io_master_awaddr,
        output wire [2:0]               io_master_awprot,

        output wire                     io_master_wvalid,
        input  wire                     io_master_wready,
        output wire [DATA_WIDTH-1:0]    io_master_wdata,
        output wire [3:0] io_master_wstrb,

        input  wire                     io_master_bvalid,
        output wire                     io_master_bready,
        input  wire [1:0]               io_master_bresp,

        output wire                     io_master_arvalid,
        input  wire                     io_master_arready,
        output wire [MEM_WIDTH-1:0]     io_master_araddr,
        output wire [2:0]               io_master_arprot,

        input  wire                     io_master_rvalid,
        output wire                     io_master_rready,
        input  wire [DATA_WIDTH-1:0]    io_master_rdata,
        input  wire [1:0]               io_master_rresp,

        /* slave 2 (CLINT) AXI4-lite bus interface */
        output wire   m_axi_clint_arvalid,
        input         s_axi_clint_arready,
        output wire [MEM_WIDTH-1:0] m_axi_clint_araddr,
        output wire [2:0]  m_axi_clint_arprot,

        input         s_axi_clint_rvalid,
        output wire   m_axi_clint_rready,
        input  [DATA_WIDTH-1:0] s_axi_clint_rdata,
        input  [1:0]  s_axi_clint_rresp,

        /* arbiter state control signal */
        input inst_fetch_flag,
        input mem_access_flag
    );

    // 在多周期处理器时，CPU不会同时取指令和访存，所以我们假设仲裁器只有两种状态
    // 状态1：允许取指令操作，阻塞访存操作
    // 状态2：允许访存操作，阻塞取指令操作
    // TODO: 在设计流水线处理器时，更新仲裁逻辑

    localparam ARBITER_PMEM_IDLE = 2'b00;
    localparam ARBITER_PMEM_INST = 2'b01;
    localparam ARBITER_PMEM_MEM  = 2'b10;

    reg [1:0] arbiter_pmem_state;

    always @(posedge aclk) begin
        if(areset) begin
            arbiter_pmem_state <= ARBITER_PMEM_IDLE;
        end else begin
            case(arbiter_pmem_state)
                ARBITER_PMEM_IDLE :
                    arbiter_pmem_state <= ARBITER_PMEM_INST;
                ARBITER_PMEM_INST :
                    if(mem_access_flag) begin
                        arbiter_pmem_state <= ARBITER_PMEM_MEM;
                    end else if(inst_fetch_flag) begin
                        arbiter_pmem_state <= ARBITER_PMEM_IDLE;
                    end
                ARBITER_PMEM_MEM :
                    if(inst_fetch_flag) begin
                        arbiter_pmem_state <= ARBITER_PMEM_INST;
                    end else if(mem_access_flag) begin
                        arbiter_pmem_state <= ARBITER_PMEM_MEM;
                    end
                default :
                    arbiter_pmem_state <= ARBITER_PMEM_IDLE;
            endcase
        end
    end

    wire arbiter_allow_lsu;
    wire arbiter_allow_ifu;

    assign arbiter_allow_lsu = (arbiter_pmem_state == ARBITER_PMEM_MEM);
    assign arbiter_allow_ifu = (arbiter_pmem_state == ARBITER_PMEM_INST);

    /* AXI4-Lite bus 中间信号 */
    wire m_awvalid;
    wire s_awready;
    wire [MEM_WIDTH-1:0] m_awaddr;
    wire [2:0] m_awprot;

    wire m_wvalid;
    wire s_wready;
    wire [DATA_WIDTH-1:0] m_wdata;
    wire [3:0] m_wstrb;

    wire s_bvalid;
    wire m_bready;
    wire [1:0] s_bresp;

    wire m_arvalid;
    wire s_arready;
    wire [MEM_WIDTH-1:0] m_araddr;
    wire [2:0] m_arprot;

    wire s_rvalid;
    wire m_rready;
    wire [DATA_WIDTH-1:0] s_rdata;
    wire [1:0] s_rresp;

    // 写通道信号驱动
    assign m_awvalid = (arbiter_allow_lsu) ? m_axi_lsu_mem_awvalid :
                       (arbiter_allow_ifu) ? 1'b0 : 1'b0;

    assign s_axi_lsu_mem_awready = (arbiter_allow_lsu) ? s_awready : 1'b0;

    assign m_awaddr = (arbiter_allow_lsu) ? m_axi_lsu_mem_awaddr :
                      (arbiter_allow_ifu) ? {MEM_WIDTH{1'b0}} : {MEM_WIDTH{1'b0}};

    assign m_awprot = (arbiter_allow_lsu) ? m_axi_lsu_mem_awprot :
                      (arbiter_allow_ifu) ? 3'b0 : 3'b0;

    assign m_wvalid = (arbiter_allow_lsu) ? m_axi_lsu_mem_wvalid :
                      (arbiter_allow_ifu) ? 1'b0 : 1'b0;

    assign s_axi_lsu_mem_wready = (arbiter_allow_lsu) ? s_wready : 1'b0;

    assign m_wdata = (arbiter_allow_lsu) ? m_axi_lsu_mem_wdata :
                     (arbiter_allow_ifu) ? {DATA_WIDTH{1'b0}} : {DATA_WIDTH{1'b0}};

    assign m_wstrb = (arbiter_allow_lsu) ? m_axi_lsu_mem_wstrb :
                     (arbiter_allow_ifu) ? 4'b0 : 4'b0;

    assign s_axi_lsu_mem_bvalid = (arbiter_allow_lsu) ? s_bvalid : 1'b0;

    assign m_bready = (arbiter_allow_lsu) ? m_axi_lsu_mem_bready :
                      (arbiter_allow_ifu) ? 1'b0 : 1'b0;

    assign s_axi_lsu_mem_bresp = (arbiter_allow_lsu) ? s_bresp : 2'b0;

    // 读通道信号驱动
    assign m_arvalid = (arbiter_allow_lsu) ? m_axi_lsu_mem_arvalid :
                       (arbiter_allow_ifu) ? m_axi_ifu_mem_arvalid : 1'b0;

    assign s_axi_lsu_mem_arready = (arbiter_allow_lsu) ? s_arready : 1'b0;
    assign s_axi_ifu_mem_arready = (arbiter_allow_ifu) ? s_arready : 1'b0;

    assign m_araddr = (arbiter_allow_lsu) ? m_axi_lsu_mem_araddr :
                      (arbiter_allow_ifu) ? m_axi_ifu_mem_araddr : {MEM_WIDTH{1'b0}};

    assign m_arprot = (arbiter_allow_lsu) ? m_axi_lsu_mem_arprot :
                      (arbiter_allow_ifu) ? m_axi_ifu_mem_arprot : 3'b0;

    assign s_axi_lsu_mem_rvalid = (arbiter_allow_lsu) ? s_rvalid : 1'b0;
    assign s_axi_ifu_mem_rvalid = (arbiter_allow_ifu) ? s_rvalid : 1'b0;

    assign m_rready = (arbiter_allow_lsu) ? m_axi_lsu_mem_rready :
                      (arbiter_allow_ifu) ? m_axi_ifu_mem_rready : 1'b0;

    assign s_axi_lsu_mem_rdata = (arbiter_allow_lsu) ? s_rdata : {DATA_WIDTH{1'b0}};
    assign s_axi_ifu_mem_rdata = (arbiter_allow_ifu) ? s_rdata : {DATA_WIDTH{1'b0}};

    assign s_axi_lsu_mem_rresp = (arbiter_allow_lsu) ? s_rresp : 2'b0;
    assign s_axi_ifu_mem_rresp = (arbiter_allow_ifu) ? s_rresp : 2'b0;

    /* 中间信号的考虑内存映射分发 */
    wire xbar_device_soc;
    wire xbar_device_clint;

    reg  xbar_soc_buff;
    reg  xbar_clint_buff;

    wire xbar_slave_soc;
    wire xbar_slave_clint;

    // SoC 设备选通逻辑：PMEM 范围 OR UART 范围
    assign xbar_device_soc = (m_awvalid) ? (
                                (m_awaddr >= PMEM_BASE && m_awaddr < PMEM_BASE + PMEM_SIZE) || 
                                (m_awaddr >= UART_MMIO_BASE && m_awaddr < UART_MMIO_BASE + UART_MMIO_SIZE)
                             ) :
                             (m_arvalid) ? (
                                (m_araddr >= PMEM_BASE && m_araddr < PMEM_BASE + PMEM_SIZE) || 
                                (m_araddr >= UART_MMIO_BASE && m_araddr < UART_MMIO_BASE + UART_MMIO_SIZE)
                             ) : 1'b0;

    // CLINT 设备选通逻辑：保持独立
    assign xbar_device_clint = (m_awvalid) ? (m_awaddr >= CLINT_MMIO_BASE && m_awaddr < CLINT_MMIO_BASE + CLINT_MMIO_SIZE) :
                               (m_arvalid) ? (m_araddr >= CLINT_MMIO_BASE && m_araddr < CLINT_MMIO_BASE + CLINT_MMIO_SIZE) : 1'b0;

    // 用于处理 AXI 握手过程中的地址阶段后的数据/响应阶段选通
    always @(posedge aclk) begin
        if (areset) begin
            xbar_soc_buff <= 1'b0;
        end else if ((io_master_bvalid && io_master_bready) || (io_master_rvalid && io_master_rready)) begin
            xbar_soc_buff <= 1'b0;
        end else if (xbar_device_soc) begin
            xbar_soc_buff <= 1'b1;
        end
    end

    always @(posedge aclk) begin
        if (areset) begin
            xbar_clint_buff <= 1'b0;
        end else if ((s_axi_clint_rvalid && m_axi_clint_rready)) begin // CLINT 仅读，故只判断 R 通道
            xbar_clint_buff <= 1'b0;
        end else if (xbar_device_clint) begin
            xbar_clint_buff <= 1'b1;
        end
    end

    // TODO: 处理访存越界异常
    assign xbar_slave_soc   = xbar_device_soc   | xbar_soc_buff;
    assign xbar_slave_clint = xbar_device_clint | xbar_clint_buff;

    assign io_master_awvalid  = xbar_slave_soc   ? m_awvalid : 1'b0;
    assign io_master_awaddr   = xbar_slave_soc   ? m_awaddr  : {MEM_WIDTH{1'b0}};
    assign io_master_awprot   = xbar_slave_soc   ? m_awprot  : 3'b0;
    assign s_awready          = xbar_slave_soc   ? io_master_awready : 1'b0;

    assign io_master_wvalid   = xbar_slave_soc   ? m_wvalid  : 1'b0;
    assign io_master_wdata    = xbar_slave_soc   ? m_wdata   : {DATA_WIDTH{1'b0}};
    assign io_master_wstrb    = xbar_slave_soc   ? m_wstrb   : 4'b0;
    assign s_wready           = xbar_slave_soc   ? io_master_wready  : 1'b0;

    assign io_master_bready   = xbar_slave_soc   ? m_bready  : 1'b0;
    assign s_bvalid           = xbar_slave_soc   ? io_master_bvalid  : 1'b0;
    assign s_bresp            = xbar_slave_soc   ? io_master_bresp   : 2'b0;

    assign io_master_arvalid  = xbar_slave_soc   ? m_arvalid : 1'b0;
    assign io_master_araddr   = xbar_slave_soc   ? m_araddr  : {MEM_WIDTH{1'b0}};
    assign io_master_arprot   = xbar_slave_soc   ? m_arprot  : 3'b0;

    assign m_axi_clint_arvalid = xbar_slave_clint ? m_arvalid : 1'b0;
    assign m_axi_clint_araddr  = xbar_slave_clint ? m_araddr  : {MEM_WIDTH{1'b0}};
    assign m_axi_clint_arprot  = xbar_slave_clint ? m_arprot  : 3'b0;
    assign s_arready          = xbar_slave_soc   ? io_master_arready :
                                xbar_slave_clint ? s_axi_clint_arready : 1'b0;

    assign io_master_rready   = xbar_slave_soc   ? m_rready  : 1'b0;
    assign m_axi_clint_rready  = xbar_slave_clint ? m_rready  : 1'b0;
    assign s_rvalid           = xbar_slave_soc   ? io_master_rvalid :
                                xbar_slave_clint ? s_axi_clint_rvalid : 1'b0;

    assign s_rdata            = xbar_slave_soc   ? io_master_rdata :
                                xbar_slave_clint ? s_axi_clint_rdata : {DATA_WIDTH{1'b0}};

    assign s_rresp            = xbar_slave_soc   ? io_master_rresp :
                                xbar_slave_clint ? s_axi_clint_rresp : 2'b0;

endmodule