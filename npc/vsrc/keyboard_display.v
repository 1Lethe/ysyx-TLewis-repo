module keyboard_display(
    input clk,
    input rst,
    input [7:0] ps2dis_data,
    input ps2dis_recFlag 
);

parameter IDLE = 4'b0001;
parameter MAKE = 4'b0010;
parameter BREAK = 4'b0100;
parameter BREAK_KEY = 4'b1000;

reg[3:0] kb_state;

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

endmodule