
module ysyx_24120013_top (
    input clk,
    input rst,
    input [31:0] pmem,
    output reg [31:0] pc
);

parameter COMMAND_WIDTH = 2;
parameter ADDR_WIDTH = 5;
parameter DATA_WIDTH = 32;

ysyx_24120013_PC u_ysyx_24120013_PC(
    .clk        	(clk         ),
    .rst        	(rst         ),
    .pc_jmp_en  	(1'b0),
    .pc_jmp_val 	(32'b0),
    .pc         	(pc          )
);

// output declaration of module ysyx_24120023_IFU
wire [31:0]IFU_inst;

ysyx_24120023_IFU u_ysyx_24120023_IFU(
    .clk      	(clk       ),
    .rst      	(rst       ),
    .inst     	(pmem      ),
    .IFU_inst 	(IFU_inst  )
);

// output declaration of module ysyx_24120013_IDU
wire [ADDR_WIDTH-1:0] IDU_raddr1;
wire [ADDR_WIDTH-1:0] IDU_raddr2;
wire [DATA_WIDTH-1:0] IDU_src1;
wire [DATA_WIDTH-1:0] IDU_src2;
wire [ADDR_WIDTH-1:0] IDU_des;
reg [31:0] IDU_imm;
reg [1:0] IDU_command;

ysyx_24120013_IDU #(
    .COMMAND_WIDTH (2),
    .ADDR_WIDTH (5),
    .DATA_WIDTH (32)
)u_ysyx_24120013_IDU(
    .clk         	(clk          ),
    .rst         	(rst          ),
    .inst        	(IFU_inst     ),
    .rdata1      	(rdata1       ),
    .rdata2      	(rdata2       ),
    .IDU_raddr1  	(IDU_raddr1   ),
    .IDU_raddr2  	(IDU_raddr2   ),
    .IDU_src1    	(IDU_src1     ),
    .IDU_src2    	(IDU_src2     ),
    .IDU_des     	(IDU_des      ),
    .IDU_imm     	(IDU_imm      ),
    .IDU_command 	(IDU_command  )
);

// output declaration of module ysyx_24120013_RegisterFile
wire [DATA_WIDTH-1:0] rdata1;
wire [DATA_WIDTH-1:0] rdata2;

ysyx_24120013_RegisterFile #(
    .ADDR_WIDTH (5),
    .DATA_WIDTH (32)
)u_ysyx_24120013_RegisterFile(
    .clk    	(clk     ),
    .rst    	(rst     ),
    .wdata  	(EXU_wdata   ),
    .waddr  	(EXU_waddr   ),
    .wen    	(EXU_wen     ),
    .raddr1 	(IDU_raddr1  ),
    .raddr2 	(IDU_raddr2  ),
    .rdata1 	(rdata1  ),
    .rdata2 	(rdata2  )
);

// output declaration of module ysyx_24120013_EXU
reg EXU_wen;
reg [ADDR_WIDTH-1:0] EXU_waddr;
reg [DATA_WIDTH-1:0] EXU_wdata;

ysyx_24120013_EXU #(
    .ADDR_WIDTH (5),
    .DATA_WIDTH (32)
)u_ysyx_24120013_EXU(
    .clk       	(clk        ),
    .rst       	(rst        ),
    .imm       	(IDU_imm    ),
    .src1      	(IDU_src1   ),
    .src2      	(IDU_src2   ),
    .des_addr   (IDU_des    ),
    .command   	(IDU_command),
    .EXU_wen   	(EXU_wen    ),
    .EXU_waddr 	(EXU_waddr  ),
    .EXU_wdata 	(EXU_wdata  )
);

endmodule
