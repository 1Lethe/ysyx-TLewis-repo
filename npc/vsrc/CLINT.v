module ysyx_24120013_CLINT #(
        MEM_WIDTH = 32, 
        DATA_WIDTH = 32,
        CLINT_MMIO_BASE,
        CLINT_MMIO_SIZE
    )(
        input aclk,
        input areset_n,

        input wire m_arvalid,
        output reg s_arready,
        input [MEM_WIDTH-1:0] m_araddr,
        input [2:0] m_arprot,

        output wire s_rvalid,
        input m_rready,
        output reg [DATA_WIDTH-1:0] s_rdata,
        output reg [1:0] s_rresp
    );

    /* device CLINT regs */
    reg [63:0] clint_mtime;

    always @(posedge aclk) begin
        if(areset_n) begin
            clint_mtime <= 64'b0;
        end else begin
            clint_mtime[31:0]  <= sim_read_RTC(CLINT_MMIO_BASE);
            clint_mtime[63:32] <= sim_read_RTC(CLINT_MMIO_BASE + 32'h4);
        end
    end

    parameter RESP_OKAY = 2'b00;

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
    wire clint_rreq;
    wire clint_rready;

    reg [MEM_WIDTH-1:0] clint_raddr_buff;
    wire [MEM_WIDTH-1:0] clint_raddr;

    // NOTE: 可能需要进一步修改这个信号
    assign clint_rreq = arshakehand;

    assign clint_rready = arshakehand | arcomplete;

    always @(posedge aclk) begin
        if(areset_n) begin
            clint_raddr_buff <= {MEM_WIDTH{1'b0}};
        end else if(clint_rreq) begin
            clint_raddr_buff <= m_araddr;
        end else if(rshakehand) begin
            clint_raddr_buff <= {MEM_WIDTH{1'b0}};
        end
    end

    assign clint_raddr = (~clint_rready) ? {MEM_WIDTH{1'b0}} :
                        (clint_rreq) ? m_araddr : clint_raddr_buff;

    wire clint_is_read_down;
    wire clint_is_read_upper;

    assign clint_is_read_down  = (clint_raddr >= CLINT_MMIO_BASE && 
                                  clint_raddr < CLINT_MMIO_BASE + 32'h4);
    assign clint_is_read_upper = (clint_raddr >= CLINT_MMIO_BASE + 4 &&     
                                  clint_raddr < CLINT_MMIO_BASE + 32'h8);

    always @(posedge aclk) begin
        if(areset_n) begin
            s_rvalid <= 1'b0;
            s_rdata <= {DATA_WIDTH{1'b0}};
            s_rresp <= 2'b0;
        end else if(clint_rreq) begin
            s_rvalid <= 1'b1;
            s_rresp <= RESP_OKAY;
            if(clint_is_read_down) begin
                s_rdata <= clint_mtime[31:0];
            end else if(clint_is_read_upper) begin
                s_rdata <= clint_mtime[63:32];
            end
        end else if(rshakehand) begin
            s_rvalid <= 1'b0;
            s_rdata <= {DATA_WIDTH{1'b0}};
            s_rresp <= 2'b0;
        end
    end

endmodule
