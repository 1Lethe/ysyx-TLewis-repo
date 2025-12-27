module pmem_sim #(MEM_WIDTH = 32, DATA_WIDTH = 32) (
        input aclk,
        input areset_n,

        input m_awvalid,
        output reg s_awready,
        input [MEM_WIDTH-1:0] m_awaddr,
        input [2:0] m_awprot,

        input m_wvalid,
        output reg s_wready,
        input [DATA_WIDTH-1:0] m_wdata,
        input [3:0] m_wstrb,

        output reg s_bvalid,
        input wire m_bready,
        output reg [1:0] s_bresp,

        input wire m_arvalid,
        output reg s_arready,
        input [MEM_WIDTH-1:0] m_araddr,
        input [2:0] m_arprot,

        output wire s_rvalid,
        input m_rready,
        output reg [DATA_WIDTH-1:0] s_rdata,
        output reg [1:0] s_rresp
    );

    parameter RESP_OKAY = 2'b00;

    /* AXI4-lite write signal */

    wire awshakehand;
    reg awcomplete;

    wire wshakehand;
    reg wcomplete;

    wire bshakehand;

    assign awshakehand = m_awvalid & s_awready;
    assign wshakehand = m_wvalid & s_wready;
    assign bshakehand = s_bvalid & m_bready;

    always @(posedge aclk) begin
        if(areset_n) begin
            awcomplete <= 1'b0;
        end else if(awshakehand) begin
            awcomplete <= 1'b1;
        end else if(bshakehand) begin
            awcomplete <= 1'b0;
        end
    end

    always @(posedge aclk) begin
        if(areset_n) begin
            wcomplete <= 1'b0;
        end else if(wshakehand) begin
            wcomplete <= 1'b1;
        end else if(bshakehand) begin
            wcomplete <= 1'b0;
        end
    end

    reg [MEM_WIDTH-1:0] awaddr_buffer;
    reg [2:0] awprot_buffer;
    
    always @(posedge aclk) begin
        if(areset_n) begin
            s_awready <= 1'b0;
        end else if(awshakehand) begin
            s_awready <= 1'b0;
        end else if(m_awvalid) begin
            s_awready <= 1'b1;
        end
    end

    always @(posedge aclk) begin
        if(areset_n) begin
            awaddr_buffer <= {MEM_WIDTH{1'b0}};
            awprot_buffer <= 3'b0;
        end else if(awshakehand) begin
            awaddr_buffer <= m_awaddr;
            awprot_buffer <= m_awprot;
        end else if(bshakehand) begin
            awaddr_buffer <= {MEM_WIDTH{1'b0}};
            awprot_buffer <= 3'b0;
        end
    end

    // TODO: AXI4-lite一次仅传输一个数据，当拓展到AXI4时，我们需要修改这里
    reg [DATA_WIDTH-1:0] wdata_buffer;
    reg [3:0] wstrb_buffer;

    always @(posedge aclk) begin
        if(areset_n) begin
            s_wready <= 1'b0;
        end else if(wshakehand) begin
            s_wready <= 1'b0;
        end else if(m_wvalid) begin
            s_wready <= 1'b1;
        end 
    end

    always @(posedge aclk) begin
        if(areset_n) begin
            wdata_buffer <= {DATA_WIDTH{1'b0}};
            wstrb_buffer <= 4'b0;
        end else if(wshakehand) begin
            wdata_buffer <= m_wdata;
            wstrb_buffer <= m_wstrb;
        end else if(bshakehand) begin
            wdata_buffer <= {DATA_WIDTH{1'b0}};
            wstrb_buffer <= 4'b0;
        end
    end

    wire mem_wready;
    wire [MEM_WIDTH-1:0] mem_waddr;
    wire [DATA_WIDTH-1:0] mem_wdata;
    wire [3:0] mem_wstrb;

    assign mem_wready = (awcomplete & wshakehand) | (awshakehand & wcomplete);
    assign mem_waddr = (~mem_wready) ? {MEM_WIDTH{1'b0}} : 
                        (awshakehand) ? (m_awaddr) : (awaddr_buffer);
    assign mem_wdata = (~mem_wready) ? {DATA_WIDTH{1'b0}} :
                        (wshakehand)  ? (m_wdata) :  (wdata_buffer); 
    assign mem_wstrb = (~mem_wready) ? 4'b0 :
                        (wshakehand)  ? (m_wstrb) :  (wstrb_buffer); 

    always @(posedge aclk) begin
        if(mem_wready) begin
            sim_pmem_write(mem_waddr, mem_wdata,{4'b0000, mem_wstrb});
        end
    end

    always @(posedge aclk) begin
        if(areset_n) begin
            s_bvalid <= 1'b0;
            s_bresp <= 2'b0;
        end else if(bshakehand) begin
            s_bvalid <= 1'b0;
            s_bresp <= 2'b0;
        end else if(awcomplete & wcomplete) begin
            s_bvalid <= 1'b1;
            s_bresp <= RESP_OKAY;
        end 
    end

    /* AXI4-lite read signal */

    wire arshakehand;
    reg arcomplete;

    wire rshakehand;

    assign arshakehand = m_arvalid & s_arready;
    assign rshakehand = s_rvalid & m_rready;

    always @(posedge aclk) begin
        if(areset_n)
            arcomplete <= 1'b0;
        else if(arshakehand)
            arcomplete <= 1'b1;
        else if(rshakehand)
            arcomplete <= 1'b0;
    end

    always @(posedge aclk) begin
        if(areset_n) begin
            s_arready <= 1'b0;
        end else if(arshakehand) begin
            s_arready <= 1'b0;
        end else if(m_arvalid) begin
            s_arready <= 1'b1;
        end
    end

    // TODO: AXI4-lite一次仅传输一个数据，当拓展到AXI4时，我们需要修改这里

    wire mem_rreq;
    wire mem_rready;

    reg [MEM_WIDTH-1:0] mem_raddr_buff;
    wire [MEM_WIDTH-1:0] mem_raddr;

    // NOTE: 可能需要进一步修改这个信号
    assign mem_rreq = arshakehand;

    assign mem_rready = arshakehand | arcomplete;

    always @(posedge aclk) begin
        if(areset_n) begin
            mem_raddr_buff <= {MEM_WIDTH{1'b0}};
        end else if(mem_rreq) begin
            mem_raddr_buff <= m_araddr;
        end else if(rshakehand) begin
            mem_raddr_buff <= {MEM_WIDTH{1'b0}};
        end
    end

    assign mem_raddr = (~mem_rready) ? {MEM_WIDTH{1'b0}} :
                        (mem_rreq) ? m_araddr : mem_raddr_buff;

    always @(posedge aclk) begin
        if(areset_n) begin
            s_rvalid <= 1'b0;
            s_rdata <= {DATA_WIDTH{1'b0}};
            s_rresp <= 2'b0;
        end else if(mem_rreq) begin
            s_rvalid <= 1'b1;
            s_rdata <= sim_pmem_read(mem_raddr);
            s_rresp <= RESP_OKAY;
        end else if(rshakehand) begin
            s_rvalid <= 1'b0;
            s_rdata <= {DATA_WIDTH{1'b0}};
            s_rresp <= 2'b0;
        end
    end

endmodule
