module keyboard_display(
    input clk,
    input rst,
    input [7:0] ps2dis_data,
    input ps2dis_recFlag,
    output wire segs_enable,
    output reg [7:0] ps2dis_seg0_1,
    output reg [7:0] ps2dis_seg2_3,
    output reg [7:0] keytime_cnt,
    output reg shift_flag,
    output reg ctrl_flag
);

parameter IDLE = 6'b000001;
parameter MAKE = 6'b000010;
parameter BREAK = 6'b000100;
parameter BREAK_KEY = 6'b001000;
parameter MAKE_SHIFT = 6'b010000;
parameter MAKE_CTRL = 6'b100000;

reg[5:0] kb_state;

assign segs_enable = kb_state == MAKE ? 1'b1 : 1'b0;

always @(posedge clk or negedge rst) begin
    if(rst) begin
        kb_state <= IDLE;
    end else
        case(kb_state)
            IDLE : begin
                if((ps2dis_recFlag == 1'b1) && (ps2dis_data == 8'h12))
                    kb_state <= MAKE_SHIFT;
                else if((ps2dis_recFlag == 1'b1) && (ps2dis_data == 8'h14))
                    kb_state <= MAKE_CTRL;
                else if(ps2dis_recFlag == 1'b1)
                    kb_state <= MAKE;
                else
                    kb_state <= kb_state;
            end
            MAKE : begin
                if((ps2dis_recFlag == 1'b1) && (ps2dis_data == 8'hF0))
                    kb_state <= BREAK;
                else
                    kb_state <= kb_state;
            end
            BREAK : begin
                if(ps2dis_recFlag == 1'b1)
                    kb_state <= BREAK_KEY;
                else begin
                    kb_state <= kb_state;     
                end
            end
            BREAK_KEY : begin
                if((ps2dis_recFlag == 1'b1) && (ps2dis_data == 8'hF0)) begin
                    kb_state <= BREAK;
                    if(shift_flag) begin shift_flag <= 1'b0; end
                    if(ctrl_flag) begin ctrl_flag <= 1'b0; end
                end else if(ps2dis_recFlag == 1'b1)
                    kb_state <= MAKE;
                else begin
                    kb_state <= kb_state;
                end
            end
            MAKE_SHIFT : begin
                if((ps2dis_recFlag == 1'b1) && (ps2dis_data != 8'hF0)) begin
                    shift_flag <= 1'b1;
                    kb_state <= MAKE;
                end else if((ps2dis_recFlag == 1'b1) && (ps2dis_data == 8'hF0)) begin
                    kb_state <= BREAK;
                end else begin
                    shift_flag <= 1'b1;
                    kb_state <= kb_state;
                end
            end
            MAKE_CTRL : begin
                if((ps2dis_recFlag == 1'b1) && (ps2dis_data != 8'hF0)) begin
                    ctrl_flag <= 1'b1;
                    kb_state <= MAKE;
                end else if((ps2dis_recFlag == 1'b1) && (ps2dis_data == 8'hF0)) begin
                    kb_state <= BREAK;
                end else begin
                    ctrl_flag <= 1'b1;
                    kb_state <= kb_state;
                end
            end
            default : kb_state <= IDLE;
        endcase
end

always @(posedge clk or negedge rst) begin
    if(rst) begin
        ps2dis_seg0_1 <= 8'b0;
    end else if(kb_state == MAKE) begin
        ps2dis_seg0_1 <= ps2dis_data;
    end
end

always @(posedge clk or negedge rst) begin
    if(rst) begin
        ps2dis_seg2_3 <= 8'b0;
    end else if(kb_state == MAKE) begin
        case(ps2dis_data) //ASCII 
            8'h16 : ps2dis_seg2_3 <= 8'h31;
            8'h1E : ps2dis_seg2_3 <= 8'h32;
            8'h26 : ps2dis_seg2_3 <= 8'h33;
            8'h25 : ps2dis_seg2_3 <= 8'h34;
            8'h2E : ps2dis_seg2_3 <= 8'h35;
            8'h36 : ps2dis_seg2_3 <= 8'h36;
            8'h3D : ps2dis_seg2_3 <= 8'h37;
            8'h3E : ps2dis_seg2_3 <= 8'h38;
            8'h46 : ps2dis_seg2_3 <= 8'h39;
            8'h45 : ps2dis_seg2_3 <= 8'h30;
            8'h1C : ps2dis_seg2_3 <= 8'h61;
            8'h32 : ps2dis_seg2_3 <= 8'h62;
            8'h21 : ps2dis_seg2_3 <= 8'h63;
            8'h23 : ps2dis_seg2_3 <= 8'h64;
            8'h24 : ps2dis_seg2_3 <= 8'h65;
            8'h2B : ps2dis_seg2_3 <= 8'h66;
            8'h34 : ps2dis_seg2_3 <= 8'h67;
            8'h33 : ps2dis_seg2_3 <= 8'h68;
            8'h43 : ps2dis_seg2_3 <= 8'h69;
            8'h3B : ps2dis_seg2_3 <= 8'h6A;
            8'h42 : ps2dis_seg2_3 <= 8'h6B;
            8'h4B : ps2dis_seg2_3 <= 8'h6C;
            8'h3A : ps2dis_seg2_3 <= 8'h6D;
            8'h31 : ps2dis_seg2_3 <= 8'h6E;
            8'h44 : ps2dis_seg2_3 <= 8'h6F;
            8'h4D : ps2dis_seg2_3 <= 8'h70;
            8'h15 : ps2dis_seg2_3 <= 8'h71;
            8'h2D : ps2dis_seg2_3 <= 8'h72;
            8'h1B : ps2dis_seg2_3 <= 8'h73;
            8'h2C : ps2dis_seg2_3 <= 8'h74;
            8'h3C : ps2dis_seg2_3 <= 8'h75;
            8'h2A : ps2dis_seg2_3 <= 8'h76;
            8'h1D : ps2dis_seg2_3 <= 8'h77;
            8'h22 : ps2dis_seg2_3 <= 8'h78;
            8'h35 : ps2dis_seg2_3 <= 8'h79;
            8'h1A : ps2dis_seg2_3 <= 8'h7A;
            default : ps2dis_seg2_3 <= 8'h00;
        endcase
    end
end

always @(posedge clk or negedge rst) begin
    if(rst) begin
        keytime_cnt <= 8'b0;
    end else if((ps2dis_recFlag == 1'b1) && (ps2dis_data == 8'hF0)) begin
        keytime_cnt <= keytime_cnt + 1'b1;
    end
end

endmodule