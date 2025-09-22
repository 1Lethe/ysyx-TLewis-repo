module ysyx_24120023_IFU #(MEM_WIDTH = 32,DATA_WIDTH = 32)(
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] pc,

    input next_inst_flag,

    input id_is_ready,
    output wire inst_is_valid,

    output wire [DATA_WIDTH-1:0] IFU_inst
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

    assign arshakehand = m_arvalid & s_arready;
    assign rshakehand = s_rvalid & m_rready;

    always @(posedge clk) begin
        if(rst) begin
            arcomplete <= 1'b0;
        end else if(arshakehand) begin
            arcomplete <= 1'b1;
        end else if(rshakehand) begin
            arcomplete <= 1'b0;
        end
    end

    reg m_arvalid;
    wire s_arready;
    reg [MEM_WIDTH-1:0] m_araddr;
    reg [2:0] m_arprot;

    wire s_rvalid;
    reg m_rready;
    wire [DATA_WIDTH-1:0] s_rdata;
    wire [1:0] s_rresp;

    always @(posedge clk) begin
        if(rst) begin
            m_arvalid <= 1'b0;
            m_araddr <= {MEM_WIDTH{1'b0}};
            m_arprot <= 3'b0;
        end else if(inst_fetch_enable) begin
            m_arvalid <= 1'b1;
            m_araddr <= pc;
            m_arprot <= 3'b100;
        end else if(arshakehand) begin
            m_arvalid <= 1'b0;
            m_araddr <= {MEM_WIDTH{1'b0}};
            m_arprot <= 3'b0;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            m_rready <= 1'b0;
        end else if(rshakehand) begin
            m_rready <= 1'b0;
        end else if(s_rvalid) begin
            m_rready <= 1'b1;
        end
    end

    assign rdata_inst = (rshakehand) ? s_rdata : {DATA_WIDTH{1'b0}};
    assign rvalid_inst = rshakehand;

    pmem_sim #(
        .MEM_WIDTH(MEM_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    )u_pmem_sim(
        .aclk   	(clk                  ),
        .areset_n   (rst                  ),
        .m_awvalid  (1'b0                 ),
        .s_awready  (                     ),
        .m_awaddr   ({MEM_WIDTH{1'b0}}    ),
        .m_awprot   (3'b0                 ),
        .m_wvalid   (1'b0                 ),
        .s_wready   (                     ),
        .m_wdata    ({DATA_WIDTH{1'b0}}   ),
        .m_wstrb    (8'b0                 ),
        .s_bvalid   (                     ),
        .m_bready   (1'b0                 ),
        .s_bresp    (                     ),
        .m_arvalid  (m_arvalid            ),
        .s_arready  (s_arready            ),
        .m_araddr   (m_araddr             ),
        .m_arprot   (m_arprot             ),
        .s_rvalid   (s_rvalid             ),
        .m_rready   (m_rready             ),
        .s_rdata    (s_rdata              ),
        .s_rresp    (s_rresp              )
    );

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
