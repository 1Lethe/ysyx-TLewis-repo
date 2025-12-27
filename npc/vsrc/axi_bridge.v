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

        // TODO: 修改这里的端口命名
        /* master 1 (lsu) AXI4-Lite bus */
        input  m_axi_pmem_lsu_awvalid,
        output wire s_axi_pmem_lsu_awready,
        input  [MEM_WIDTH-1:0] m_axi_pmem_lsu_awaddr,
        input  [2:0] m_axi_pmem_lsu_awprot,

        input  m_axi_pmem_lsu_wvalid,
        output wire s_axi_pmem_lsu_wready,
        input  [DATA_WIDTH-1:0] m_axi_pmem_lsu_wdata,
        input  [3:0] m_axi_pmem_lsu_wstrb,

        output wire s_axi_pmem_lsu_bvalid,
        input  m_axi_pmem_lsu_bready,
        output wire [1:0] s_axi_pmem_lsu_bresp,

        input  m_axi_pmem_lsu_arvalid,
        output wire s_axi_pmem_lsu_arready,
        input  [MEM_WIDTH-1:0] m_axi_pmem_lsu_araddr,
        input  [2:0] m_axi_pmem_lsu_arprot,

        output wire s_axi_pmem_lsu_rvalid,
        input  m_axi_pmem_lsu_rready,
        output wire [DATA_WIDTH-1:0] s_axi_pmem_lsu_rdata,
        output wire [1:0] s_axi_pmem_lsu_rresp,

        /* master 2 (ifu) AXI4-Lite bus */
        input  m_axi_pmem_ifu_arvalid,
        output wire s_axi_pmem_ifu_arready,
        input  [MEM_WIDTH-1:0] m_axi_pmem_ifu_araddr,
        input  [2:0]  m_axi_pmem_ifu_arprot,

        output wire s_axi_pmem_ifu_rvalid,
        input  m_axi_pmem_ifu_rready,
        output wire [DATA_WIDTH-1:0] s_axi_pmem_ifu_rdata,
        output wire [1:0]  s_axi_pmem_ifu_rresp,

        /* slave 1 (pmem) AXI4-Lite bus */
        output wire m_axi_pmem_awvalid,
        input  s_axi_pmem_awready,
        output wire [MEM_WIDTH-1:0] m_axi_pmem_awaddr,
        output wire [2:0] m_axi_pmem_awprot,

        output wire m_axi_pmem_wvalid,
        input  s_axi_pmem_wready,
        output wire [DATA_WIDTH-1:0] m_axi_pmem_wdata,
        output wire [3:0] m_axi_pmem_wstrb,

        input  s_axi_pmem_bvalid,
        output wire m_axi_pmem_bready,
        input  [1:0] s_axi_pmem_bresp,

        output wire m_axi_pmem_arvalid,
        input  s_axi_pmem_arready,
        output wire [MEM_WIDTH-1:0] m_axi_pmem_araddr,
        output wire [2:0] m_axi_pmem_arprot,

        input  s_axi_pmem_rvalid,
        output wire m_axi_pmem_rready,
        input  [DATA_WIDTH-1:0] s_axi_pmem_rdata,
        input  [1:0] s_axi_pmem_rresp,

        // TODO: 整合这里的SOC信号
        /* slave 2 (uart) AXI4-lite bus */
        output wire m_axi_uart_awvalid,
        input  s_axi_uart_awready,
        output wire [MEM_WIDTH-1:0] m_axi_uart_awaddr,
        output wire [2:0] m_axi_uart_awprot,

        output wire m_axi_uart_wvalid,
        input  s_axi_uart_wready,
        output wire [DATA_WIDTH-1:0] m_axi_uart_wdata,
        output wire [3:0] m_axi_uart_wstrb,

        input  s_axi_uart_bvalid,
        output wire m_axi_uart_bready,
        input  [1:0] s_axi_uart_bresp,

        /* slave 3 (CLINT) AXI4-lite bus */
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
    assign m_awvalid = (arbiter_allow_lsu) ? m_axi_pmem_lsu_awvalid :
                    (arbiter_allow_ifu) ? 1'b0 : 1'b0;

    assign s_axi_pmem_lsu_awready = (arbiter_allow_lsu) ? s_awready : 1'b0;

    assign m_awaddr = (arbiter_allow_lsu) ? m_axi_pmem_lsu_awaddr :
                    (arbiter_allow_ifu) ? {MEM_WIDTH{1'b0}} : {MEM_WIDTH{1'b0}};

    assign m_awprot = (arbiter_allow_lsu) ? m_axi_pmem_lsu_awprot :
                    (arbiter_allow_ifu) ? 3'b0 : 3'b0;

    assign m_wvalid = (arbiter_allow_lsu) ? m_axi_pmem_lsu_wvalid :
                    (arbiter_allow_ifu) ? 1'b0 : 1'b0;

    assign s_axi_pmem_lsu_wready = (arbiter_allow_lsu) ? s_wready : 1'b0;

    assign m_wdata = (arbiter_allow_lsu) ? m_axi_pmem_lsu_wdata :
                    (arbiter_allow_ifu) ? {DATA_WIDTH{1'b0}} : {DATA_WIDTH{1'b0}};

    assign m_wstrb = (arbiter_allow_lsu) ? m_axi_pmem_lsu_wstrb :
                    (arbiter_allow_ifu) ? 4'b0 : 4'b0;

    assign s_axi_pmem_lsu_bvalid = (arbiter_allow_lsu) ? s_bvalid : 1'b0;

    assign m_bready = (arbiter_allow_lsu) ? m_axi_pmem_lsu_bready :
                    (arbiter_allow_ifu) ? 1'b0 : 1'b0;

    assign s_axi_pmem_lsu_bresp = (arbiter_allow_lsu) ? s_bresp : 2'b0;

    // 读通道信号驱动
    assign m_arvalid = (arbiter_allow_lsu) ? m_axi_pmem_lsu_arvalid :
                    (arbiter_allow_ifu) ? m_axi_pmem_ifu_arvalid : 1'b0;

    assign s_axi_pmem_lsu_arready = (arbiter_allow_lsu) ? s_arready : 1'b0;
    assign s_axi_pmem_ifu_arready = (arbiter_allow_ifu) ? s_arready : 1'b0;

    assign m_araddr = (arbiter_allow_lsu) ? m_axi_pmem_lsu_araddr :
                    (arbiter_allow_ifu) ? m_axi_pmem_ifu_araddr : {MEM_WIDTH{1'b0}};

    assign m_arprot = (arbiter_allow_lsu) ? m_axi_pmem_lsu_arprot :
                    (arbiter_allow_ifu) ? m_axi_pmem_ifu_arprot : 3'b0;

    assign s_axi_pmem_lsu_rvalid = (arbiter_allow_lsu) ? s_rvalid : 1'b0;
    assign s_axi_pmem_ifu_rvalid = (arbiter_allow_ifu) ? s_rvalid : 1'b0;

    assign m_rready = (arbiter_allow_lsu) ? m_axi_pmem_lsu_rready :
                    (arbiter_allow_ifu) ? m_axi_pmem_ifu_rready : 1'b0;

    assign s_axi_pmem_lsu_rdata = (arbiter_allow_lsu) ? s_rdata : {DATA_WIDTH{1'b0}};
    assign s_axi_pmem_ifu_rdata = (arbiter_allow_ifu) ? s_rdata : {DATA_WIDTH{1'b0}};

    assign s_axi_pmem_lsu_rresp = (arbiter_allow_lsu) ? s_rresp : 2'b0;
    assign s_axi_pmem_ifu_rresp = (arbiter_allow_ifu) ? s_rresp : 2'b0;

    /* 中间信号的考虑内存映射分发 */
    wire xbar_device_pmem;
    wire xbar_device_uart;
    wire xbar_device_clint;

    reg xbar_pmem_buff;
    reg xbar_uart_buff;
    reg xbar_clint_buff;

    wire xbar_slave_pmem;
    wire xbar_slave_uart;
    wire xbar_slave_clint;

    assign xbar_device_pmem = (m_awvalid) ? (m_awaddr >= PMEM_BASE && 
                                             m_awaddr < PMEM_BASE + PMEM_SIZE) :
                              (m_arvalid) ? (m_araddr >= PMEM_BASE && 
                                             m_araddr < PMEM_BASE + PMEM_SIZE) : 1'b0;

    assign xbar_device_uart = (m_awvalid) ? (m_awaddr >= UART_MMIO_BASE && 
                                             m_awaddr < UART_MMIO_BASE + UART_MMIO_SIZE) :
                              (m_arvalid) ? (m_araddr >= UART_MMIO_BASE && 
                                             m_araddr < UART_MMIO_BASE + UART_MMIO_SIZE) : 1'b0;

    assign xbar_device_clint = (m_awvalid) ? (m_awaddr >= CLINT_MMIO_BASE && 
                                              m_awaddr < CLINT_MMIO_BASE + CLINT_MMIO_SIZE) :
                               (m_arvalid) ? (m_araddr >= CLINT_MMIO_BASE && 
                                              m_araddr < CLINT_MMIO_BASE + CLINT_MMIO_SIZE) : 1'b0;

    // 抛出仿存错误停止仿真进行，保存现场
    // TODO: 更优雅的实现？
    always @(*) begin
        if(m_arvalid) begin
            if(~xbar_device_pmem & ~xbar_device_uart & ~xbar_device_clint) begin
                sim_hardware_fault_handle(1, m_araddr);
            end
        end
    end

    always @(posedge aclk) begin
        if(areset) begin
            xbar_pmem_buff <= 1'b0;
        end else if((s_bvalid & m_bready) | (s_rvalid & m_rready)) begin
            xbar_pmem_buff <= 1'b0;
        end else if(xbar_device_pmem) begin
            xbar_pmem_buff <= 1'b1;
        end
    end

    always @(posedge aclk) begin
        if(areset) begin
            xbar_uart_buff <= 1'b0;
        end else if((s_bvalid & m_bready) | (s_rvalid & m_rready)) begin
            xbar_uart_buff <= 1'b0;
        end else if(xbar_device_uart) begin
            xbar_uart_buff <= 1'b1;
        end
    end

    always @(posedge aclk) begin
        if(areset) begin
            xbar_clint_buff <= 1'b0;
        end else if((s_bvalid & m_bready) | (s_rvalid & m_rready)) begin
            xbar_clint_buff <= 1'b0;
        end else if(xbar_device_clint) begin
            xbar_clint_buff <= 1'b1;
        end
    end

    // TODO: 处理访存越界异常
    assign xbar_slave_pmem = xbar_device_pmem | xbar_pmem_buff;
    assign xbar_slave_uart = xbar_device_uart | xbar_uart_buff;
    assign xbar_slave_clint = xbar_device_clint | xbar_clint_buff;


    // slave 1 (pmem)
    assign m_axi_pmem_awvalid = (xbar_slave_pmem) ? m_awvalid : 1'b0;
    assign m_axi_pmem_awaddr  = (xbar_slave_pmem) ? m_awaddr  : {MEM_WIDTH{1'b0}};
    assign m_axi_pmem_awprot  = (xbar_slave_pmem) ? m_awprot  : 3'b0;

    assign m_axi_pmem_wvalid  = (xbar_slave_pmem) ? m_wvalid  : 1'b0;
    assign m_axi_pmem_wdata   = (xbar_slave_pmem) ? m_wdata   : {DATA_WIDTH{1'b0}};
    assign m_axi_pmem_wstrb   = (xbar_slave_pmem) ? m_wstrb   : 4'b0;

    assign m_axi_pmem_bready  = (xbar_slave_pmem) ? m_bready  : 1'b0;

    assign m_axi_pmem_arvalid = (xbar_slave_pmem) ? m_arvalid : 1'b0;
    assign m_axi_pmem_araddr  = (xbar_slave_pmem) ? m_araddr  : {MEM_WIDTH{1'b0}};
    assign m_axi_pmem_arprot  = (xbar_slave_pmem) ? m_arprot  : 3'b0;

    assign m_axi_pmem_rready  = (xbar_slave_pmem) ? m_rready  : 1'b0;

    // slave 2 (uart)
    assign m_axi_uart_awvalid = (xbar_slave_uart) ? m_awvalid : 1'b0;
    assign m_axi_uart_awaddr  = (xbar_slave_uart) ? m_awaddr  : {MEM_WIDTH{1'b0}};
    assign m_axi_uart_awprot  = (xbar_slave_uart) ? m_awprot  : 3'b0;

    assign m_axi_uart_wvalid  = (xbar_slave_uart) ? m_wvalid  : 1'b0;
    assign m_axi_uart_wdata   = (xbar_slave_uart) ? m_wdata   : {DATA_WIDTH{1'b0}};
    assign m_axi_uart_wstrb   = (xbar_slave_uart) ? m_wstrb   : 4'b0;

    assign m_axi_uart_bready  = (xbar_slave_uart) ? m_bready  : 1'b0;

    // slave 3 (clint)
    assign m_axi_clint_arvalid = (xbar_slave_clint) ? m_arvalid : 1'b0;
    assign m_axi_clint_araddr  = (xbar_slave_clint) ? m_araddr  : {MEM_WIDTH{1'b0}};
    assign m_axi_clint_arprot  = (xbar_slave_clint) ? m_arprot  : 3'b0;

    assign m_axi_clint_rready  = (xbar_slave_clint) ? m_rready  : 1'b0;

    // slave 相关信号分配
    assign s_awready = (xbar_slave_pmem) ? s_axi_pmem_awready :
                    (xbar_slave_uart) ? s_axi_uart_awready : 1'b0;

    assign s_wready  = (xbar_slave_pmem) ? s_axi_pmem_wready :
                    (xbar_slave_uart) ? s_axi_uart_wready : 1'b0;

    assign s_bvalid  = (xbar_slave_pmem) ? s_axi_pmem_bvalid :
                    (xbar_slave_uart) ? s_axi_uart_bvalid : 1'b0;

    assign s_bresp   = (xbar_slave_pmem) ? s_axi_pmem_bresp :
                    (xbar_slave_uart) ? s_axi_uart_bresp : 2'b0;

    assign s_arready = (xbar_slave_pmem) ? s_axi_pmem_arready :
                    (xbar_slave_uart) ? 1'b0 :
                    (xbar_slave_clint) ? s_axi_clint_arready : 1'b0;

    assign s_rvalid  = (xbar_slave_pmem) ? s_axi_pmem_rvalid :
                    (xbar_slave_uart) ? 1'b0 :
                    (xbar_slave_clint) ? s_axi_clint_rvalid : 1'b0;

    assign s_rdata   = (xbar_slave_pmem) ? s_axi_pmem_rdata :
                    (xbar_slave_uart) ? {DATA_WIDTH{1'b0}} :
                    (xbar_slave_clint) ? s_axi_clint_rdata : {DATA_WIDTH{1'b0}};

    assign s_rresp   = (xbar_slave_pmem) ? s_axi_pmem_rresp :
                    (xbar_slave_uart) ? 2'b0 :
                    (xbar_slave_clint) ? s_axi_clint_rresp : 2'b0;

endmodule