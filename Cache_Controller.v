module CacheController (
    input clock,
    input reset,
    input [31:0] cpu_addr,
    input cpu_read,
    input cpu_write,
    input [31:0] cpu_wdata,
    output reg [31:0] cpu_rdata,
    output reg cpu_ready,
    output reg [31:0] mem_addr,
    output reg mem_read,
    output reg mem_write,
    output reg [31:0] mem_wdata,
    input [31:0] mem_rdata,
    input mem_ready
);

parameter INDEX_BITS = 5;
parameter OFFSET_BITS = 2;
parameter TAG_BITS = 25;

localparam INDEX_SIZE = 1 << INDEX_BITS;

reg [TAG_BITS-1:0] tag [0:INDEX_SIZE-1];
reg [31:0] data [0:INDEX_SIZE-1][0:3];
reg valid [0:INDEX_SIZE-1];
reg dirty [0:INDEX_SIZE-1];

localparam IDLE = 2'b00;
localparam COMPARE = 2'b01;
localparam FETCH = 2'b10;

reg [1:0] state;
reg [4:0] saved_index;
reg [24:0] saved_tag;
reg [31:0] saved_addr;
reg saved_read;
reg saved_write;
reg [31:0] saved_wdata;

wire [24:0] addr_tag = cpu_addr[31:7];
wire [4:0] addr_index = cpu_addr[6:2];
wire [1:0] addr_offset = cpu_addr[1:0];

integer i, j;
integer init_i, init_j;

initial begin
    for (init_i = 0; init_i < INDEX_SIZE; init_i = init_i + 1) begin
        valid[init_i] = 1'b0;
        dirty[init_i] = 1'b0;
        for (init_j = 0; init_j < 4; init_j = init_j + 1) begin
            data[init_i][init_j] = 32'b0;
        end
    end
end

always @(posedge clock or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        cpu_ready <= 1'b0;
        mem_read <= 1'b0;
        mem_write <= 1'b0;
        for (i = 0; i < INDEX_SIZE; i = i + 1) begin
            valid[i] <= 1'b0;
        end
    end else begin
        case (state)
            IDLE: begin
                cpu_ready <= 1'b0;
                mem_read <= 1'b0;
                mem_write <= 1'b0;
                if (cpu_read || cpu_write) begin
                    saved_index <= addr_index;
                    saved_tag <= addr_tag;
                    saved_addr <= cpu_addr;
                    saved_read <= cpu_read;
                    saved_write <= cpu_write;
                    saved_wdata <= cpu_wdata;
                    state <= COMPARE;
                end
            end
            
            COMPARE: begin
                if (valid[saved_index] && tag[saved_index] == saved_tag) begin
                    if (saved_read) begin
                        cpu_rdata <= data[saved_index][saved_addr[1:0]];
                        cpu_ready <= 1'b1;
                        state <= IDLE;
                    end else if (saved_write) begin
                        data[saved_index][saved_addr[1:0]] <= saved_wdata;
                        mem_addr <= saved_addr;
                        mem_write <= 1'b1;
                        mem_wdata <= saved_wdata;
                        state <= FETCH;
                    end
                end else begin
                    if (saved_write) begin
                        mem_addr <= saved_addr;
                        mem_write <= 1'b1;
                        mem_wdata <= saved_wdata;
                        state <= FETCH;
                    end else begin
                        mem_addr <= {saved_addr[31:2], 2'b00};
                        mem_read <= 1'b1;
                        state <= FETCH;
                    end
                end
            end
            
            FETCH: begin
                if (mem_ready) begin
                    mem_read <= 1'b0;
                    mem_write <= 1'b0;
                    if (saved_write) begin
                        cpu_ready <= 1'b1;
                        state <= IDLE;
                    end else begin
                        valid[saved_index] <= 1'b1;
                        tag[saved_index] <= saved_tag;
                        data[saved_index][0] <= mem_rdata;
                        data[saved_index][1] <= mem_rdata + 32'h00000004;
                        data[saved_index][2] <= mem_rdata + 32'h00000008;
                        data[saved_index][3] <= mem_rdata + 32'h0000000C;
                        cpu_rdata <= data[saved_index][saved_addr[1:0]];
                        cpu_ready <= 1'b1;
                        state <= IDLE;
                    end
                end
            end
        endcase
    end
end

endmodule