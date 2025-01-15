module ysyx_24120013_EXU #(ADDR_WIDTH = 32, DATA_WIDTH = 32)(
        input clk,
        input rst,
        input imm,
        input src1,
        input src2,
        input des,
        input command,
        output reg EXU_wen,
        output reg [ADDR_WIDTH-1:0] EXU_waddr,
        output reg [DATA_WIDTH-1:0] EXU_wdata
    );

    assign EXU_wen = (des != 0) ? des : 1'b0;
    assign EXU_waddr = des;

    always @(*) begin
        case (command)
            2'b01 :
                EXU_data <= src1 + imm;
            default :
                EXU_data <= {DATA_WIDTH{1'b0}};
        endcase
    end

endmodule
