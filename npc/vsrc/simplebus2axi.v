module ysyx_24120013_simplebus2axi4 #(MEM_WIDTH = 32, DATA_WIDTH = 32) (
    input clk,
    input rst,

    input wire simplebus_wr_req,
    input wire [MEM_WIDTH-1:0] simplebus_wr_addr,
    input wire [DATA_WIDTH-1:0] simplebus_wr_data,
    input wire [3:0] simplebus_wr_mask,
    input wire [2:0] simplebus_wr_size,
    input wire [2:0] simplebus_wr_prot,
    output wire [1:0]  simplebus_wr_resp,
    output wire simplebus_wr_complete,

    input wire  simplebus_rd_req,
    input wire  [MEM_WIDTH-1:0] simplebus_rd_addr,
    input wire [2:0] simplebus_rd_size,
    input wire [2:0] simplebus_rd_prot,
    output wire [DATA_WIDTH-1:0] simplebus_rd_data,
    output wire [1:0]  simplebus_rd_resp,
    output wire simplebus_rd_complete,

    output reg m_axi_awvalid,
    input wire s_axi_awready,
    output reg [MEM_WIDTH-1:0] m_axi_awaddr,
    output reg [2:0] m_axi_awsize,
    output reg [2:0] m_axi_awprot,

    output reg m_axi_wvalid,
    input wire s_axi_wready,
    output reg [DATA_WIDTH-1:0] m_axi_wdata,
    output reg [3:0] m_axi_wstrb,

    input wire s_axi_bvalid,
    output reg m_axi_bready,
    input wire [1:0] s_axi_bresp,

    output reg m_axi_arvalid,
    input wire s_axi_arready,
    output reg [MEM_WIDTH-1:0] m_axi_araddr,
    output reg [2:0] m_axi_arsize,
    output reg [2:0] m_axi_arprot,

    input wire s_axi_rvalid,
    output reg m_axi_rready,
    input wire [DATA_WIDTH-1:0] s_axi_rdata,
    input wire [1:0] s_axi_rresp
);

    wire awshakehand;
    wire wshakehand;
    wire bshakehand;

    assign awshakehand = m_axi_awvalid & s_axi_awready;
    assign wshakehand  = m_axi_wvalid  & s_axi_wready;
    assign bshakehand  = s_axi_bvalid  & m_axi_bready;

    always @(posedge clk) begin
        if(rst) begin
            m_axi_awvalid <= 1'b0;
            m_axi_awaddr  <= {MEM_WIDTH{1'b0}};
            m_axi_awsize  <= 3'b0;
            m_axi_awprot  <= 3'b0;
        end else if(simplebus_wr_req) begin
            m_axi_awvalid <= 1'b1;
            m_axi_awaddr  <= simplebus_wr_addr;
            m_axi_awsize  <= simplebus_wr_size;
            m_axi_awprot  <= simplebus_wr_prot;
        end else if(awshakehand) begin
            m_axi_awvalid <= 1'b0;
            m_axi_awaddr  <= {MEM_WIDTH{1'b0}};
            m_axi_awsize  <= 3'b0;
            m_axi_awprot  <= 3'b0;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            m_axi_wvalid <= 1'b0;
            m_axi_wdata  <= {DATA_WIDTH{1'b0}};
            m_axi_wstrb  <= 4'b0;
        end else if(awshakehand) begin
            m_axi_wvalid <= 1'b1;
            m_axi_wdata  <= simplebus_wr_data;
            m_axi_wstrb  <= simplebus_wr_mask;
        end else if(wshakehand) begin
            m_axi_wvalid <= 1'b0;
            m_axi_wdata  <= {DATA_WIDTH{1'b0}};
            m_axi_wstrb  <= 4'b0;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            m_axi_bready <= 1'b0;
        end else if(bshakehand) begin
            m_axi_bready <= 1'b0;
        end else if(s_axi_bvalid) begin
            m_axi_bready <= 1'b1;
        end
    end

    assign simplebus_wr_resp = s_axi_bresp;
    assign simplebus_rd_resp = s_axi_rresp;
    assign simplebus_wr_complete = bshakehand;

    wire arshakehand;
    reg arcomplete;
    wire rshakehand;

    assign arshakehand = m_axi_arvalid & s_axi_arready;
    assign rshakehand  = s_axi_rvalid  & m_axi_rready;

    always @(posedge clk) begin
        if(rst) begin
            arcomplete <= 1'b0;
        end else if(arshakehand) begin
            arcomplete <= 1'b1;
        end else if(rshakehand) begin
            arcomplete <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            m_axi_arvalid <= 1'b0;
            m_axi_araddr  <= {MEM_WIDTH{1'b0}};
            m_axi_arsize  <= 3'b0;
            m_axi_arprot  <= 3'b0;
        end else if(simplebus_rd_req) begin
            m_axi_arvalid <= 1'b1;
            m_axi_araddr  <= simplebus_rd_addr;
            m_axi_arsize  <= simplebus_rd_size;
            m_axi_arprot  <= simplebus_rd_prot;
        end else if(arshakehand) begin
            m_axi_arvalid <= 1'b0;
            m_axi_araddr  <= {MEM_WIDTH{1'b0}};
            m_axi_arsize  <= 3'b0;
            m_axi_arprot  <= 3'b0;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            m_axi_rready <= 1'b0;
        end else if(rshakehand) begin
            m_axi_rready <= 1'b0;
        end else if(s_axi_rvalid) begin
            m_axi_rready <= 1'b1;
        end
    end

    assign simplebus_rd_data     = (rshakehand) ? s_axi_rdata : {DATA_WIDTH{1'b0}};
    assign simplebus_rd_complete = rshakehand;

endmodule