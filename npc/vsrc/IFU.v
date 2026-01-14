module ysyx_24120013_IFU #(MEM_WIDTH = 32,DATA_WIDTH = 32)(
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] pc,

    input next_inst_flag,

    input id_is_ready,
    output wire inst_is_valid,
    output wire [DATA_WIDTH-1:0] IFU_inst,

    output wire simplebus_ifu_mem_rd_req,
    output wire [MEM_WIDTH-1:0] simplebus_ifu_mem_rd_addr,
    output wire [2:0] simplebus_ifu_mem_rd_size,
    output wire [2:0] simplebus_ifu_mem_rd_prot,
    input [DATA_WIDTH-1:0] simplebus_ifu_mem_rd_data,
    input [1:0]  simplebus_ifu_mem_rd_resp,
    input simplebus_ifu_mem_rd_complete
);

    wire [DATA_WIDTH-1:0] inst_fetch;

    reg inst_fetch_enable;

    reg [DATA_WIDTH-1:0] inst_buffer;
    reg inst_buffer_enable;

    always @(posedge clk) begin
        if(rst) begin
            inst_fetch_enable <= 1'b1;
        end 
        else begin
            inst_fetch_enable <= next_inst_flag;
        end
    end

    wire [DATA_WIDTH-1:0] rdata_inst;
    wire rvalid_inst;

    assign simplebus_ifu_mem_rd_req = inst_fetch_enable;
    assign simplebus_ifu_mem_rd_addr = pc;
    assign simplebus_ifu_mem_rd_size = 3'b010; // always 4 bytes
    assign simplebus_ifu_mem_rd_prot = 3'b100;
    assign rdata_inst = simplebus_ifu_mem_rd_data;
    assign rvalid_inst = simplebus_ifu_mem_rd_complete;

`ifdef ysyx_24120013_USE_CPP_SIM_ENV
    // resp != 0
    always @(posedge clk) begin
        if(rvalid_inst) begin
            if(simplebus_ifu_mem_rd_resp != 2'b00) begin
                sim_hardware_fault_handle(3, simplebus_ifu_mem_rd_addr);
            end
        end
    end
`endif

    assign inst_fetch = rdata_inst;
    assign inst_is_valid = rvalid_inst | inst_buffer_enable;

    always @(posedge clk) begin
        if(rst) begin
            inst_buffer_enable <= 1'b0;
            inst_buffer <= {DATA_WIDTH{1'b0}};
        end
        else if(rvalid_inst & ~next_inst_flag) begin
            inst_buffer_enable <= 1'b1;
            inst_buffer <= inst_fetch;
        end
        else if(next_inst_flag)begin
            inst_buffer_enable <= 1'b0;
            inst_buffer <= {DATA_WIDTH{1'b0}};
        end
    end

    assign IFU_inst = (~inst_is_valid) ? {DATA_WIDTH{1'b0}} : 
                      (inst_buffer_enable) ? inst_buffer : inst_fetch;

endmodule
