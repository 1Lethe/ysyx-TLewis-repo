`include "define/exu_command.v"

module ysyx_24120013_alu #(ADDR_WIDTH = 5, DATA_WIDTH = 32)(
    input [DATA_WIDTH-1:0] src1,
    input [DATA_WIDTH-1:0] src2,
    input [`ysyx_24120013_ALUOP_WIDTH-1:0] alu_op,

<<<<<<< HEAD
    output reg [DATA_WIDTH-1:0] alu_result
);

    wire [DATA_WIDTH-1:0] add_res;
    wire [DATA_WIDTH-1:0] and_res;
    wire [DATA_WIDTH-1:0] or_res;
    wire [DATA_WIDTH-1:0] xor_res;
    wire [DATA_WIDTH-1:0] src2_res;

    assign add_res = src1 + src2;
    assign and_res = src1 & src2;
    assign or_res  = src1 | src2;
    assign src2_res = src2;

    assign alu_result = ({DATA_WIDTH{alu_op[0]}} & add_res) |
                        ({DATA_WIDTH{alu_op[10]}}& src2_res);
=======
    output wire [DATA_WIDTH-1:0] alu_result,
    output wire branch_less,
    output wire branch_zero
);

    wire op_add;
    wire op_sub;
    wire op_slt;
    wire op_sltu;
    wire op_and;
    wire op_or;
    wire op_xor;
    wire op_sll;
    wire op_srl;
    wire op_sra;
    wire op_src2;
    wire op_equ;
    wire op_neq;
    wire op_get;
    wire op_getu;

    wire adder_neg;
    wire [DATA_WIDTH-1:0] adder_a;
    wire [DATA_WIDTH-1:0] adder_b;
    wire [DATA_WIDTH-1:0] adder_cin;
    wire [DATA_WIDTH-1:0] adder_result;
    wire adder_cout;

    wire [63:0] sr64_res;

    wire [DATA_WIDTH-1:0] add_sub_res;
    wire [DATA_WIDTH-1:0] slt_res;
    wire [DATA_WIDTH-1:0] sltu_res;
    wire [DATA_WIDTH-1:0] and_res;
    wire [DATA_WIDTH-1:0] or_res;
    wire [DATA_WIDTH-1:0] xor_res;
    wire [DATA_WIDTH-1:0] sll_res;
    wire [DATA_WIDTH-1:0] sr_res;
    wire [DATA_WIDTH-1:0] src2_res;
    wire [DATA_WIDTH-1:0] equ_res;
    wire [DATA_WIDTH-1:0] neq_res;
    wire [DATA_WIDTH-1:0] get_res;
    wire [DATA_WIDTH-1:0] getu_res;

    assign op_add  = alu_op[0];
    assign op_sub  = alu_op[1];
    assign op_slt  = alu_op[2];
    assign op_sltu = alu_op[3];
    assign op_and  = alu_op[4];
    assign op_or   = alu_op[5];
    assign op_xor  = alu_op[6];
    assign op_sll  = alu_op[7];
    assign op_srl  = alu_op[8];
    assign op_sra  = alu_op[9];
    assign op_src2 = alu_op[10];
    assign op_equ  = alu_op[11];
    assign op_neq  = alu_op[12];
    assign op_get  = alu_op[13];
    assign op_getu = alu_op[14];

    assign adder_neg = op_sub | op_slt | op_sltu | op_equ | op_neq | op_get | op_getu;
    assign adder_a   = src1;
    assign adder_b   = (adder_neg) ? ~src2 : src2;
    assign adder_cin = (adder_neg) ? 1     : 0;
    assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;

    assign add_sub_res = adder_result;

    assign slt_res[DATA_WIDTH-1:1] = {(DATA_WIDTH-1){1'b0}};
    assign slt_res[0] = (src1[DATA_WIDTH-1] & ~src2[DATA_WIDTH-1]) |
                           ((src1[DATA_WIDTH-1] ~^ src2[DATA_WIDTH-1]) & adder_result[DATA_WIDTH-1]);
    
    assign sltu_res[DATA_WIDTH-1:1] = {(DATA_WIDTH-1){1'b0}};
    assign sltu_res[0] = ~adder_cout;

    assign and_res = src1 & src2;
    assign or_res  = src1 | src2;
    assign xor_res = src1 ^ src2;

    assign sll_res  = src1 << src2[4:0];
    assign sr64_res = {{32{op_sra & src1[31]}}, src1[31:0]} >> src2[4:0];
    assign sr_res   = sr64_res[31:0];

    assign src2_res = src2;

    assign equ_res[DATA_WIDTH-1:1] = {(DATA_WIDTH-1){1'b0}};
    assign equ_res[0] = (adder_result == 0) && (adder_cout == 1);

    assign neq_res[DATA_WIDTH-1:1] = {(DATA_WIDTH-1){1'b0}};
    assign neq_res[0] = ~equ_res[0];

    assign get_res[DATA_WIDTH-1:1] = {(DATA_WIDTH-1){1'b0}};
    assign get_res[0] = ~slt_res[0];

    assign getu_res[DATA_WIDTH-1:1] = {(DATA_WIDTH-1){1'b0}};
    assign getu_res[0] = ~sltu_res[0];

    assign alu_result = ({DATA_WIDTH{op_add | op_sub}}  & add_sub_res) |
                        ({DATA_WIDTH{op_slt }}          & slt_res    ) |
                        ({DATA_WIDTH{op_sltu}}          & sltu_res   ) |
                        ({DATA_WIDTH{op_and }}          & and_res    ) |
                        ({DATA_WIDTH{op_or  }}          & or_res     ) |
                        ({DATA_WIDTH{op_xor }}          & xor_res    ) |
                        ({DATA_WIDTH{op_sll }}          & sll_res    ) |
                        ({DATA_WIDTH{op_srl }}          & sr_res     ) |
                        ({DATA_WIDTH{op_sra }}          & sr_res     ) |
                        ({DATA_WIDTH{op_src2}}          & src2_res   ) |
                        ({DATA_WIDTH{op_equ }}          & equ_res    ) |
                        ({DATA_WIDTH{op_neq }}          & neq_res    ) |
                        ({DATA_WIDTH{op_get }}          & get_res    ) |
                        ({DATA_WIDTH{op_getu}}          & getu_res   );

    assign branch_less = ((op_slt  | op_get ) & slt_res[0] ) |
                         ((op_sltu | op_getu) & sltu_res[0]);
    assign branch_zero = equ_res[0];
>>>>>>> npc

endmodule