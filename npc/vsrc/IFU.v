module ysyx_24120023_IFU #(DATA_WIDTH = 32)(
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] pc,

    input next_inst_flag,

    input id_is_ready,
    output reg inst_is_valid,

    output wire [DATA_WIDTH-1:0] IFU_inst
);

    reg [DATA_WIDTH-1:0] inst_fetch;

    wire inst_allowin;
    wire inst_waiting;

    reg inst_fetch_enable;

    reg [DATA_WIDTH-1:0] inst_buffer;
    reg inst_buffer_enable;

    assign inst_allowin = inst_is_valid & id_is_ready;
    assign inst_waiting = inst_is_valid & ~id_is_ready;

    always @(posedge clk) begin
        if(rst) begin
            inst_fetch_enable <= 1'b1;
        end 
        else begin
            inst_fetch_enable <= next_inst_flag;
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            inst_fetch <= {DATA_WIDTH{1'b0}};
            inst_is_valid <= 1'b0;
        end
        else begin
            if(inst_fetch_enable) begin
                inst_fetch <= sim_pmem_read(pc);
                inst_is_valid <= 1'b1; // TODO: 修改使其符合真实存储器的时序(异步握手)
            end
            else begin
                inst_fetch <= {DATA_WIDTH{1'b0}};
                inst_is_valid <= 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            inst_buffer_enable <= 1'b0;
            inst_buffer <= {DATA_WIDTH{1'b0}};
        end
        else if(inst_waiting) begin
            inst_buffer_enable <= 1'b1;
            inst_buffer <= inst_fetch;
        end
        else begin
            inst_buffer_enable <= 1'b0;
            inst_buffer <= {DATA_WIDTH{1'b0}};
        end
    end

    assign IFU_inst = (~inst_is_valid) ? {DATA_WIDTH{1'b0}} : 
                      (inst_buffer_enable) ? inst_buffer : inst_fetch;

endmodule
