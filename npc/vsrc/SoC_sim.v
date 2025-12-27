// NOTE: 接入SoC后不再使用
module SoC_sim #(
        MEM_WIDTH = 32, 
        DATA_WIDTH = 32,

        PMEM_BASE = 32'h80000000,
        PMEM_SIZE =  32'h8000000,
        UART_MMIO_BASE = 32'ha00003f8,
        UART_MMIO_SIZE = 32'h8
      )(
    input clk,
    input rst,

    // --- Write Address Channel ---
    input  wire                     io_slave_awvalid,
    output wire                     io_slave_awready,
    input  wire [MEM_WIDTH-1:0]     io_slave_awaddr,
    input  wire [2:0]               io_slave_awprot,

    // --- Write Data Channel ---
    input  wire                     io_slave_wvalid,
    output wire                     io_slave_wready,
    input  wire [DATA_WIDTH-1:0]    io_slave_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] io_slave_wstrb,

    // --- Write Response Channel ---
    output wire                     io_slave_bvalid,
    input  wire                     io_slave_bready,
    output wire [1:0]               io_slave_bresp,

    // --- Read Address Channel ---
    input  wire                     io_slave_arvalid,
    output wire                     io_slave_arready,
    input  wire [MEM_WIDTH-1:0]     io_slave_araddr,
    input  wire [2:0]               io_slave_arprot,

    // --- Read Data Channel ---
    output wire                     io_slave_rvalid,
    input  wire                     io_slave_rready,
    output wire [DATA_WIDTH-1:0]    io_slave_rdata,
    output wire [1:0]               io_slave_rresp,

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
    input  [1:0] s_axi_uart_bresp
    );

    // ------------------ 地址译码 ------------------
    // 写操作目标判断
    wire sel_aw_pmem = io_slave_awvalid && (io_slave_awaddr >= PMEM_BASE && io_slave_awaddr < PMEM_BASE + PMEM_SIZE);
    wire sel_aw_uart = io_slave_awvalid && (io_slave_awaddr >= UART_MMIO_BASE && io_slave_awaddr < UART_MMIO_BASE + UART_MMIO_SIZE);
    
    // 读操作目标判断 (仅 PMEM)
    wire sel_ar_pmem = io_slave_arvalid && (io_slave_araddr >= PMEM_BASE && io_slave_araddr < PMEM_BASE + PMEM_SIZE);

    // ------------------ 事务状态锁存 ------------------
    reg pmem_write_active, uart_write_active, pmem_read_active;

    always @(posedge clk) begin
        if (rst) begin
            pmem_write_active <= 1'b0;
            uart_write_active <= 1'b0;
            pmem_read_active  <= 1'b0;
        end else begin
            // 写响应阶段结束
            if (io_slave_bvalid && io_slave_bready) begin
                pmem_write_active <= 1'b0;
                uart_write_active <= 1'b0;
            end else begin
                if (sel_aw_pmem) pmem_write_active <= 1'b1;
                if (sel_aw_uart) uart_write_active <= 1'b1;
            end
            
            // 读数据阶段结束
            if (io_slave_rvalid && io_slave_rready) begin
                pmem_read_active <= 1'b0;
            end else if (sel_ar_pmem) begin
                pmem_read_active <= 1'b1;
            end
        end
    end

    wire pmem_wr_en = sel_aw_pmem | pmem_write_active;
    wire uart_wr_en = sel_aw_uart | uart_write_active;
    wire pmem_rd_en = sel_ar_pmem | pmem_read_active;

    // 1. 写地址通道 (AW)
    assign m_axi_pmem_awvalid = pmem_wr_en ? io_slave_awvalid : 1'b0;
    assign m_axi_pmem_awaddr  = pmem_wr_en ? io_slave_awaddr  : {MEM_WIDTH{1'b0}};
    assign m_axi_pmem_awprot  = pmem_wr_en ? io_slave_awprot  : 3'b0;

    assign m_axi_uart_awvalid = uart_wr_en ? io_slave_awvalid : 1'b0;
    assign m_axi_uart_awaddr  = uart_wr_en ? io_slave_awaddr  : {MEM_WIDTH{1'b0}};
    assign m_axi_uart_awprot  = uart_wr_en ? io_slave_awprot  : 3'b0;

    assign io_slave_awready   = pmem_wr_en ? s_axi_pmem_awready :
                                uart_wr_en ? s_axi_uart_awready : 1'b0;

    // 2. 写数据通道 (W)
    assign m_axi_pmem_wvalid  = pmem_wr_en ? io_slave_wvalid : 1'b0;
    assign m_axi_pmem_wdata   = pmem_wr_en ? io_slave_wdata  : {DATA_WIDTH{1'b0}};
    assign m_axi_pmem_wstrb   = pmem_wr_en ? io_slave_wstrb  : 4'b0;

    assign m_axi_uart_wvalid  = uart_wr_en ? io_slave_wvalid : 1'b0;
    assign m_axi_uart_wdata   = uart_wr_en ? io_slave_wdata  : {DATA_WIDTH{1'b0}};
    assign m_axi_uart_wstrb   = uart_wr_en ? io_slave_wstrb  : 4'b0;

    assign io_slave_wready    = pmem_wr_en ? s_axi_pmem_wready :
                                uart_wr_en ? s_axi_uart_wready : 1'b0;

    // 3. 写响应通道 (B)
    assign m_axi_pmem_bready  = pmem_wr_en ? io_slave_bready : 1'b0;
    assign m_axi_uart_bready  = uart_wr_en ? io_slave_bready : 1'b0;

    assign io_slave_bvalid    = pmem_wr_en ? s_axi_pmem_bvalid :
                                uart_wr_en ? s_axi_uart_bvalid : 1'b0;
    assign io_slave_bresp     = pmem_wr_en ? s_axi_pmem_bresp  :
                                uart_wr_en ? s_axi_uart_bresp  : 2'b0;

    // 4. 读地址通道 (AR) - 仅分配给 PMEM
    assign m_axi_pmem_arvalid = pmem_rd_en ? io_slave_arvalid : 1'b0;
    assign m_axi_pmem_araddr  = pmem_rd_en ? io_slave_araddr  : {MEM_WIDTH{1'b0}};
    assign m_axi_pmem_arprot  = pmem_rd_en ? io_slave_arprot  : 3'b0;
    assign io_slave_arready   = pmem_rd_en ? s_axi_pmem_arready : 1'b0;

    // 5. 读数据通道 (R) - 仅来自 PMEM
    assign m_axi_pmem_rready  = pmem_rd_en ? io_slave_rready : 1'b0;
    assign io_slave_rvalid    = pmem_rd_en ? s_axi_pmem_rvalid : 1'b0;
    assign io_slave_rdata     = pmem_rd_en ? s_axi_pmem_rdata  : {DATA_WIDTH{1'b0}};
    assign io_slave_rresp     = pmem_rd_en ? s_axi_pmem_rresp  : 2'b0;

endmodule