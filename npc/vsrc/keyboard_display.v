module keyboard_display(
    input clk,
    input rst,
    input [7:0] ps2dis_data,
    input ps2dis_recFlag,
    output wire segs_enable,
    output reg [7:0] ps2dis_seg0_1,
    output reg [7:0] keytime_cnt
);

parameter IDLE = 4'b0001;
parameter MAKE = 4'b0010;
parameter BREAK = 4'b0100;
parameter BREAK_KEY = 4'b1000;

reg[3:0] kb_state;

assign segs_enable = kb_state == MAKE ? 1'b1 : 1'b0;

always @(posedge clk or negedge rst) begin
    if(rst) begin
        kb_state <= IDLE;
    end else
        case(kb_state)
            IDLE : kb_state <= MAKE;
            MAKE : begin
                if((ps2dis_recFlag == 1'b1) && (ps2dis_data == 8'hF0))
                    kb_state <= BREAK;
                else
                    kb_state <= kb_state;
            end
            BREAK : begin
                if(ps2dis_recFlag == 1'b1)
                    kb_state <= BREAK_KEY;
                else
                    kb_state <= kb_state;     
            end
            BREAK_KEY : begin
                if(ps2dis_recFlag == 1'b1)
                    kb_state <= MAKE;
                else
                    kb_state <= kb_state;
            end
            default : kb_state <= IDLE;
        endcase
end

always @(posedge clk or negedge rst) begin
    if(rst) begin
        ps2dis_seg0_1 <= 8'b0;
        keytime_cnt <= 8'b0;
    end else if(kb_state == MAKE) begin
        ps2dis_seg0_1 <= ps2dis_data;
    end else if((ps2dis_recFlag == 1'b1) && (ps2dis_data == 8'hF0)) begin
        keytime_cnt <= keytime_cnt + 1'b1;
    end
end


endmodule