// ============================================
// MEM_Stage.v - Memory Access Stage
// ============================================

module EX_MemReg_RV (
    input clock,
    input registerWrite,
    input memoryToRegister,
    input memoryWrite,
    input memoryRead,
    input [31:0] ALUresult,
    input [31:0] writeData,
    input [4:0] writeRegister,
    output reg registerWriteOut,
    output reg memoryToRegisterOut,
    output reg memoryWriteOut,
    output reg memoryReadOut,
    output reg [31:0] ALUresultOut,
    output reg [31:0] writeDataOut,
    output reg [4:0] writeRegisterOut
);
always @(posedge clock) begin
    writeDataOut <= writeData;
    memoryToRegisterOut <= memoryToRegister;
    writeRegisterOut <= writeRegister;
    registerWriteOut <= registerWrite;
    memoryWriteOut <= memoryWrite;
    memoryReadOut <= memoryRead;
    ALUresultOut <= ALUresult;
end
endmodule

module MainMemory (
    input clock,
    input mem_read,
    input mem_write,
    input [31:0] addr,
    input [31:0] wdata,
    output reg [31:0] rdata,
    output reg ready
);

reg [31:0] memory [0:1023];

integer i;
initial begin
    for (i = 0; i < 1024; i = i + 1) begin
        memory[i] = 32'h00000000;
    end
    memory[0] = 32'h00000001;
    memory[1] = 32'h00000001;
    memory[2] = 32'h00000000;
end

always @(posedge clock) begin
    ready <= 1'b0;
    if (mem_read) begin
        rdata <= memory[addr[11:2]];
        ready <= 1'b1;
    end
    if (mem_write) begin
        memory[addr[11:2]] <= wdata;
        ready <= 1'b1;
    end
end
endmodule

module DataMemory_RV (
    input clock,
    input memoryWrite,
    input memoryRead,
    input [31:0] address,
    input [31:0] writeData,
    output reg [31:0] readData,
    input reset
);

wire [31:0] cache_rdata;
wire cache_ready;
wire mem_ready;
wire [31:0] mem_rdata;
wire [31:0] cache_mem_addr;
wire cache_mem_read;
wire cache_mem_write;
wire [31:0] cache_mem_wdata;

CacheController cache (
    .clock(clock),
    .reset(reset),
    .cpu_addr(address),
    .cpu_read(memoryRead),
    .cpu_write(memoryWrite),
    .cpu_wdata(writeData),
    .cpu_rdata(cache_rdata),
    .cpu_ready(cache_ready),
    .mem_addr(cache_mem_addr),
    .mem_read(cache_mem_read),
    .mem_write(cache_mem_write),
    .mem_wdata(cache_mem_wdata),
    .mem_rdata(mem_rdata),
    .mem_ready(mem_ready)
);

MainMemory main_mem (
    .clock(clock),
    .mem_read(cache_mem_read),
    .mem_write(cache_mem_write),
    .addr(cache_mem_addr),
    .wdata(cache_mem_wdata),
    .rdata(mem_rdata),
    .ready(mem_ready)
);

always @(posedge clock) begin
    if (cache_ready) begin
        readData <= cache_rdata;
    end else if (memoryRead) begin
        readData <= mem_rdata;
    end
end

endmodule