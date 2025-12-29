`include "cpu_defines.v"
module ysyx_24120013_RegisterFile #(ADDR_WIDTH = 5, DATA_WIDTH = 32) (
        input clk,
        input rst,
        input [DATA_WIDTH-1:0] wdata,
        input [ADDR_WIDTH-1:0] waddr,
        input wen,
        input [ADDR_WIDTH-1:0] raddr1,
        input [ADDR_WIDTH-1:0] raddr2,
        output wire [DATA_WIDTH-1:0] rdata1,
        output wire [DATA_WIDTH-1:0] rdata2,

        input [DATA_WIDTH-1:0] csr_wdata1,
        input [`ysyx_24120013_CSR_ADDR_WIDTH-1:0] csr_waddr1,
        input [DATA_WIDTH-1:0] csr_wdata2,
        input [`ysyx_24120013_CSR_ADDR_WIDTH-1:0] csr_waddr2,
        input [DATA_WIDTH-1:0] csr_wdata3,
        input [`ysyx_24120013_CSR_ADDR_WIDTH-1:0] csr_waddr3, // MSTATUS CSR for difftest
        input csr_wen,
        input [`ysyx_24120013_CSR_ADDR_WIDTH-1:0] csr_raddr,
        output wire [DATA_WIDTH-1:0] csr_rdata,

        `ifdef ysyx_24120013_USE_CPP_SIM_ENV
        output wire [DATA_WIDTH-1:0] rf_difftest [2**ADDR_WIDTH-1:0],
        output wire [DATA_WIDTH-1:0] mstatus_difftest,
        output wire [DATA_WIDTH-1:0] mtvec_difftest,
        output wire [DATA_WIDTH-1:0] mepc_difftest,
        output wire [DATA_WIDTH-1:0] mcause_difftest,
        `endif

        input ex_is_valid,
        output wire wb_is_ready,

        output wire next_inst_flag
    );

    assign wb_is_ready = ~rst;
    assign next_inst_flag = ex_is_valid;

    reg [DATA_WIDTH-1:0] rf [2**ADDR_WIDTH-1:0];
    reg [DATA_WIDTH-1:0] mstatus;
    reg [DATA_WIDTH-1:0] mtvec;
    reg [DATA_WIDTH-1:0] mepc;
    reg [DATA_WIDTH-1:0] mcause;

`ifdef ysyx_24120013_USE_CPP_SIM_ENV
    assign rf_difftest = rf;
    assign mstatus_difftest = mstatus;
    assign mtvec_difftest = mtvec;
    assign mepc_difftest = mepc;
    assign mcause_difftest = mcause;
`endif

    wire is_mstatus_r;
    wire is_mtvec_r;
    wire is_mepc_r;
    wire is_mcause_r;

    always @(posedge clk) begin
        if(wen) begin
            rf[waddr] <= wdata;
        end 
        rf[0] <= {DATA_WIDTH{1'b0}};
    end

    assign rdata1 = rf[raddr1];
    assign rdata2 = rf[raddr2];

    always @(posedge clk) begin
        if(csr_wen == 1'b1) begin
            if(csr_waddr3 == `ysyx_24120013_MSTATUS)
                mstatus <= csr_wdata3;
        end
    end
    always @(posedge clk) begin
        if(csr_wen == 1'b1) begin
            if(csr_waddr1 == `ysyx_24120013_MTVEC)
                mtvec <= csr_wdata1;
            else if(csr_waddr2 == `ysyx_24120013_MTVEC)
                mtvec <= csr_wdata2;
        end
    end
    always @(posedge clk) begin
        if(csr_wen == 1'b1) begin
            if(csr_waddr1 == `ysyx_24120013_MEPC)
                mepc <= csr_wdata1;
            else if(csr_waddr2 == `ysyx_24120013_MEPC)
                mepc <= csr_wdata2;
        end
    end
    always @(posedge clk) begin
        if(csr_wen == 1'b1) begin
            if(csr_waddr1 == `ysyx_24120013_MCAUSE)
                mcause <= csr_wdata1;
            else if(csr_waddr2 == `ysyx_24120013_MCAUSE)
                mcause <= csr_wdata2;
        end
    end

    assign is_mstatus_r = (csr_raddr == `ysyx_24120013_MSTATUS);
    assign is_mtvec_r   = (csr_raddr == `ysyx_24120013_MTVEC  );
    assign is_mepc_r    = (csr_raddr == `ysyx_24120013_MEPC   );
    assign is_mcause_r  = (csr_raddr == `ysyx_24120013_MCAUSE );

    assign csr_rdata = ({DATA_WIDTH{is_mstatus_r}} & mstatus ) |
                       ({DATA_WIDTH{is_mtvec_r}}   & mtvec   ) |
                       ({DATA_WIDTH{is_mepc_r}}    & mepc    ) |
                       ({DATA_WIDTH{is_mcause_r}}  & mcause  );

endmodule
