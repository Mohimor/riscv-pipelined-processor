// ============================================
// IF_Stage.v - Instruction Fetch Stage
// ============================================

module PC (
    input clock, 
    input wire [31:0] nextPC,
    output reg [31:0] outPC,
    input reset,
    input holdPC
);
always @(posedge reset) begin
    outPC <= 32'hFFFFFFFC;
end
always @(posedge clock) begin
    if (holdPC == 0) begin
        outPC <= nextPC;
    end
end
endmodule

module InstructionMemory(
    input clock,
    input [31:0] pc,
    output reg [31:0] readData
);
reg [31:0] instructionMemory [0:1060];

initial begin
    instructionMemory[0] = 32'h00002083;
    instructionMemory[1] = 32'h00402103;
    instructionMemory[2] = 32'h002081B3;
    instructionMemory[3] = 32'h00310233;
    instructionMemory[4] = 32'h004182B3;
    instructionMemory[5] = 32'h00520333;
    instructionMemory[6] = 32'h006283B3;
    instructionMemory[7] = 32'h00730433;
    instructionMemory[8] = 32'h008384B3;
    instructionMemory[9] = 32'h00940533;
    instructionMemory[10] = 32'h00A02423;
    
    instructionMemory[1024] = 32'h00000001;
    instructionMemory[1025] = 32'h00000001;
    instructionMemory[1026] = 32'h00000000;
end

always @ (pc) begin
    readData <= instructionMemory[pc >> 2];
end
endmodule

module IF_ID_reg(
    input clk,
    input wire[31:0] PCplus4,
    input wire[31:0] instrIn,
    output reg [31:0] instrOut,
    input hold,
    output reg[31:0] PCplus4Out,
    input IF_flush
);
always @(posedge clk) begin
    if (hold == 1'b0) begin
        PCplus4Out <= PCplus4;
        instrOut <= instrIn;
    end
    else if (IF_flush == 1'b1) begin
        PCplus4Out <= PCplus4;
        instrOut <= 32'b0;
    end
end
endmodule