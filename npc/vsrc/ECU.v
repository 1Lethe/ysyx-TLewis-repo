`include "define/exu_command.v"

module ysyx_24120013_ECU #(ADDR_WIDTH = 5, DATA_WIDTH = 32)(
        input clk,
        input rst,
        input [`ysyx_24120013_ECU_WIDTH-1:0] ecu_op,
        input [DATA_WIDTH-1:0] ecu_pc,

        input [`ysyx_24120013_CSR_ADDR_WIDTH-1:0] ecu_csr_waddr,
        input [DATA_WIDTH-1:0] alu_csr_rdata,
        input [DATA_WIDTH-1:0] csr_rdata,
        input [DATA_WIDTH-1:0] ecu_reg_rdata,

        output wire [DATA_WIDTH-1:0] ecu_reg_wdata,
        output wire csr_wen,
        output wire [`ysyx_24120013_CSR_ADDR_WIDTH-1:0] csr_waddr1,
        output wire [`ysyx_24120013_CSR_ADDR_WIDTH-1:0] csr_waddr2,
        output wire [`ysyx_24120013_CSR_ADDR_WIDTH-1:0] csr_waddr3,
        output wire [DATA_WIDTH-1:0] csr_wdata1,
        output wire [DATA_WIDTH-1:0] csr_wdata2,
        output wire [DATA_WIDTH-1:0] csr_wdata3,

        output wire ecu_jump_pc_flag,
        output wire [DATA_WIDTH-1:0] ecu_jump_pc
    );

    wire ecu_is_wreg;
    wire ecu_is_w_mstatus;

    assign ecu_is_wreg = (ecu_op[0] | ecu_op[1]);

    assign ecu_reg_wdata = (ecu_is_wreg) ? csr_rdata : {DATA_WIDTH{1'b0}};

    assign csr_wen = ecu_op[0] | ecu_op[1] | ecu_op[2];

    assign ecu_is_w_mstatus = (ecu_op[0] == 1'b1 && ecu_csr_waddr == `ysyx_24120013_MSTATUS) |
                              (ecu_op[1] == 1'b1 && ecu_csr_waddr == `ysyx_24120013_MSTATUS) | 
                              (ecu_op[2] == 1'b1);

    assign csr_waddr1 = ({`ysyx_24120013_CSR_ADDR_WIDTH{ecu_op[0] | ecu_op[1]}} & ecu_csr_waddr        ) |
                        ({`ysyx_24120013_CSR_ADDR_WIDTH{ecu_op[2]}}             & `ysyx_24120013_MEPC  );
    assign csr_waddr2 = ({`ysyx_24120013_CSR_ADDR_WIDTH{ecu_op[2]}}             & `ysyx_24120013_MCAUSE);
    assign csr_waddr3 = (ecu_is_w_mstatus == 1'b1) ? `ysyx_24120013_MSTATUS : {`ysyx_24120013_CSR_ADDR_WIDTH{1'b0}};

    assign csr_wdata1 = ({DATA_WIDTH{ecu_op[0]}} & alu_csr_rdata) |
                        ({DATA_WIDTH{ecu_op[1]}} & ecu_reg_rdata) |
                        ({DATA_WIDTH{ecu_op[2]}} & ecu_pc       ); // ecall write epc to csr_mepc
    assign csr_wdata2 = ({DATA_WIDTH{ecu_op[2]}} & 32'hb        ); // ecall write 0xb to csr_mcause
    assign csr_wdata3 = (ecu_is_w_mstatus == 1'b1) ? 32'h1800 : {DATA_WIDTH{1'b0}} ; // ecall write 0x1800 to csr_mstatus

    assign ecu_jump_pc_flag = (ecu_op[2] | ecu_op[3]);
    assign ecu_jump_pc = (ecu_jump_pc_flag) ? csr_rdata : {DATA_WIDTH{1'b0}}; // ecall:mtvec or mret:mepc

endmodule