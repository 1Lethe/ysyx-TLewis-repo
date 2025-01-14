module alu(
    input clk,
    input rst,
    input [2:0] alu_command,
    input [3:0] inA,
    input [3:0] inB,
    output reg[3:0] alu_out,
    output reg alu_iszero,
    output reg alu_is_overflow,
    output reg alu_cout
);
    wire[3:0] t_add_Cin;
    wire overflow_flag;
    wire[3:0] compare_out;

    assign alu_iszero = (alu_out == 4'b0000) ? 1'b1 : 1'b0;
    assign overflow_flag = (inA[3] == t_add_Cin[3]) && (compare_out[3] != inA[3]);
    assign t_add_Cin = ~inB + 1'b1;
    assign compare_out = inA + t_add_Cin;

    always @(*) begin
        case(alu_command)
            3'b000 : begin
                {alu_cout,alu_out} = inA + inB;
                alu_is_overflow = (inA[3] == inB[3]) && (alu_out[3] != inA[3]) ? 1'b1 : 1'b0;
            end
            3'b001 : begin
                {alu_cout,alu_out} = inA + t_add_Cin;
                alu_is_overflow = (inA[3] == t_add_Cin[3]) && (alu_out[3] != inA[3]) ? 1'b1 : 1'b0;
            end
            3'b010 : begin
                alu_out = ~inA;
                alu_cout = 1'b0;
                alu_is_overflow = 1'b0;
            end
            3'b011 : begin
                alu_out = inA & inB;
                alu_cout = 1'b0;
                alu_is_overflow = 1'b0;
            end
            3'b100 : begin
                alu_out = inA | inB;
                alu_cout = 1'b0;
                alu_is_overflow = 1'b0;
            end
            3'b101 : begin
                alu_out = inA ^ inB;
                alu_cout = 1'b0;
                alu_is_overflow = 1'b0;
            end
            3'b110 : begin
                alu_out = {3'b000,compare_out[3] ^ overflow_flag};
                alu_cout = 1'b0;
                alu_is_overflow = 1'b0;
            end
            3'b111 : begin
                alu_out = (inA == inB) ? 4'b1 : 4'b0; 
                alu_cout = 1'b0;
                alu_is_overflow = 1'b0;
            end
            default : begin
                alu_out = 4'b0000;
            end
        endcase
    end

endmodule