module ysyx_24120013_EXU #(ADDR_WIDTH = 32, DATA_WIDTH = 32)(
        input clk,
        input rst,
        input [19:0] imm,
        input [4:0] src1,
        input [4:0] src2,
        input [4:0] des,
        input [1:0] command,
        output reg EXU_wen,
        output reg [ADDR_WIDTH-1:0] EXU_waddr,
        output reg [DATA_WIDTH-1:0] EXU_wdata
    );

    assign EXU_wen = (des != 5'b0) ? 1'b1 : 1'b0;
    assign EXU_waddr = des;

    always @(*) begin
        case (command)
            2'b01 :
                EXU_wdata = src1 + imm;
            default :
                EXU_wdata = {DATA_WIDTH{1'b0}};
        endcase
    end

endmodule
