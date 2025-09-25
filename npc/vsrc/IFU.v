module ysyx_24120023_IFU #(MEM_WIDTH = 32,DATA_WIDTH = 32)(
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] pc,

    input next_inst_flag,

    input id_is_ready,
    output wire inst_is_valid,
    output wire [DATA_WIDTH-1:0] IFU_inst,

    output reg m_axi_pmem_ifu_arvalid,
    input wire s_axi_pmem_ifu_arready,
    output reg [MEM_WIDTH-1:0] m_axi_pmem_ifu_araddr,
    output reg [2:0]  m_axi_pmem_ifu_arprot,

    input wire s_axi_pmem_ifu_rvalid,
    output reg m_axi_pmem_ifu_rready,
    input wire [DATA_WIDTH-1:0] s_axi_pmem_ifu_rdata,
    input wire [1:0]  s_axi_pmem_ifu_rresp
);

    wire [DATA_WIDTH-1:0] inst_fetch;

    reg inst_fetch_enable;

    reg [DATA_WIDTH-1:0] inst_buffer;
    reg inst_buffer_enable;

    always @(posedge clk) begin
        if(rst) begin
            inst_fetch_enable <= 1'b1;
        end 
        else begin
            inst_fetch_enable <= next_inst_flag;
        end
    end

    wire [DATA_WIDTH-1:0] rdata_inst;
    wire rvalid_inst;

    wire arshakehand;
    reg arcomplete;

    wire rshakehand;

    assign arshakehand = m_axi_pmem_ifu_arvalid & s_axi_pmem_ifu_arready;
    assign rshakehand = s_axi_pmem_ifu_rvalid & m_axi_pmem_ifu_rready;

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
            m_axi_pmem_ifu_arvalid <= 1'b0;
            m_axi_pmem_ifu_araddr  <= {MEM_WIDTH{1'b0}};
            m_axi_pmem_ifu_arprot  <= 3'b0;
        end else if(inst_fetch_enable) begin
            m_axi_pmem_ifu_arvalid <= 1'b1;
            m_axi_pmem_ifu_araddr  <= pc;
            m_axi_pmem_ifu_arprot  <= 3'b100;
        end else if(arshakehand) begin
            m_axi_pmem_ifu_arvalid <= 1'b0;
            m_axi_pmem_ifu_araddr  <= {MEM_WIDTH{1'b0}};
            m_axi_pmem_ifu_arprot  <= 3'b0;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            m_axi_pmem_ifu_rready <= 1'b0;
        end else if(rshakehand) begin
            m_axi_pmem_ifu_rready <= 1'b0;
        end else if(s_axi_pmem_ifu_rvalid) begin
            m_axi_pmem_ifu_rready <= 1'b1;
        end
    end

    assign rdata_inst = (rshakehand) ? s_axi_pmem_ifu_rdata : {DATA_WIDTH{1'b0}};
    assign rvalid_inst = rshakehand;

    assign inst_fetch = rdata_inst;
    assign inst_is_valid = rvalid_inst | inst_buffer_enable;

    always @(posedge clk) begin
        if(rst) begin
            inst_buffer_enable <= 1'b0;
            inst_buffer <= {DATA_WIDTH{1'b0}};
        end
        else if(rvalid_inst & ~next_inst_flag) begin
            inst_buffer_enable <= 1'b1;
            inst_buffer <= inst_fetch;
        end
        else if(next_inst_flag)begin
            inst_buffer_enable <= 1'b0;
            inst_buffer <= {DATA_WIDTH{1'b0}};
        end
    end

    assign IFU_inst = (~inst_is_valid) ? {DATA_WIDTH{1'b0}} : 
                      (inst_buffer_enable) ? inst_buffer : inst_fetch;

endmodule
