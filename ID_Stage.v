// ============================================
// ID_Stage.v - Instruction Decode Stage
// ============================================

module ControlUnit_RV (
    input [6:0] opcode,
    output reg registerDestination,
    output reg branch,
    output reg memoryRead,
    output reg memoryToRegister,
    output reg [3:0] ALUop,
    output reg memoryWrite,
    output reg AluSrc,
    output reg registerWrite,
    input reset
);
always @(posedge reset) begin
    registerDestination <= 1'b0;
    branch <= 1'b0;
    memoryRead <= 1'b0;
    memoryToRegister <= 1'b0;
    ALUop <= 4'b0000;
    memoryWrite <= 1'b0;
    AluSrc <= 1'b0;
    registerWrite <= 1'b0;
end

always @(opcode) begin
    case (opcode)
        7'b0110011: begin
            registerDestination <= 1'b1;
            branch <= 1'b0;
            memoryRead <= 1'b0;
            memoryToRegister <= 1'b0;
            memoryWrite <= 1'b0;
            AluSrc <= 1'b0;
            registerWrite <= 1'b1;
            ALUop <= 4'b0010;
        end
        
        7'b0010011: begin
            registerDestination <= 1'b0;
            branch <= 1'b0;
            memoryRead <= 1'b0;
            memoryToRegister <= 1'b0;
            memoryWrite <= 1'b0;
            AluSrc <= 1'b1;
            registerWrite <= 1'b1;
            ALUop <= 4'b0101;
        end
        
        7'b0000011: begin
            registerDestination <= 1'b0;
            branch <= 1'b0;
            memoryRead <= 1'b1;
            memoryToRegister <= 1'b1;
            memoryWrite <= 1'b0;
            AluSrc <= 1'b1;
            registerWrite <= 1'b1;
            ALUop <= 4'b0000;
        end
        
        7'b0100011: begin
            registerDestination <= 1'b0;
            branch <= 1'b0;
            memoryRead <= 1'b0;
            memoryToRegister <= 1'b0;
            memoryWrite <= 1'b1;
            AluSrc <= 1'b1;
            registerWrite <= 1'b0;
            ALUop <= 4'b0000;
        end
        
        7'b1100011: begin
            registerDestination <= 1'b0;
            branch <= 1'b1;
            memoryRead <= 1'b0;
            memoryToRegister <= 1'b0;
            memoryWrite <= 1'b0;
            AluSrc <= 1'b0;
            registerWrite <= 1'b0;
            ALUop <= 4'b0001;
        end
        
        default: begin
            registerDestination <= 1'b0;
            branch <= 1'b0;
            memoryRead <= 1'b0;
            memoryToRegister <= 1'b0;
            ALUop <= 4'b0000;
            memoryWrite <= 1'b0;
            AluSrc <= 1'b0;
            registerWrite <= 1'b0;
        end
    endcase
end
endmodule

module RegisterFile_RV(
    input clock,
    input [4:0] readRegister1,
    input [4:0] readRegister2,
    input [4:0] RegisterAddress,
    input [31:0] WriteData,
    input writeSignal,
    output reg [31:0] ReadData1,
    output reg [31:0] ReadData2,
    input reset
);
reg [31:0] registers[0:31];
integer i;

always @(posedge reset) begin
    for (i = 0; i < 32; i = i + 1) begin
        registers[i] <= 32'h00000000;
    end
    registers[1] <= 32'h00000001;
    registers[2] <= 32'h00000001;
end

always @(readRegister1, readRegister2) begin
    ReadData1 <= registers[readRegister1];
    ReadData2 <= registers[readRegister2];
end

always @(negedge clock) begin
    if (writeSignal == 1 && RegisterAddress != 0) begin
        registers[RegisterAddress] <= WriteData;
    end
end
endmodule

module Comparator(
    input [31:0] input1,
    input [31:0] input2,
    output result
);
assign result = (input1 == input2) ? 1'b1 : 1'b0;
endmodule

module SignExtend_RV (
    input [31:0] instruction,
    input [2:0] imm_type,
    output reg [31:0] result
);
wire [31:0] imm_i = {{20{instruction[31]}}, instruction[31:20]};
wire [31:0] imm_s = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
wire [31:0] imm_b = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8]};
wire [31:0] imm_u = {instruction[31:12], 12'b0};
wire [31:0] imm_j = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21]};

always @(*) begin
    case (imm_type)
        3'b000: result = imm_i;
        3'b001: result = imm_s;
        3'b010: result = imm_b;
        3'b011: result = imm_u;
        3'b100: result = imm_j;
        default: result = 32'bx;
    endcase
end
endmodule

module ShiftLeft2(
    output [31:0] result,
    input [31:0] input1
);
assign result = input1 << 2;
endmodule

module HazardDetectionUnit_RV(
    input ID_ExMemRead,
    input EX_MemMemRead,
    input [4:0] ID_Ex_Rd,
    input [31:0] IF_ID_Instr,
    output reg holdPC,
    output reg holdIF_ID,
    output reg muxSelector
);

wire [4:0] IF_ID_rs1 = IF_ID_Instr[19:15];
wire [4:0] IF_ID_rs2 = IF_ID_Instr[24:20];
wire [6:0] IF_ID_opcode = IF_ID_Instr[6:0];

initial begin
    holdPC <= 0;
    holdIF_ID <= 0;
    muxSelector <= 0;
end

always @(*) begin
    if (ID_ExMemRead && ID_Ex_Rd != 0 && 
        (ID_Ex_Rd == IF_ID_rs1 || ID_Ex_Rd == IF_ID_rs2)) begin
        holdPC <= 1;
        holdIF_ID <= 1;
        muxSelector <= 1;
    end
    else if (IF_ID_opcode == 7'b1100011 && !holdPC && !holdIF_ID) begin
        holdPC <= 1;
        holdIF_ID <= 1;
        muxSelector <= 1;
    end
    else begin
        holdPC <= 0;
        holdIF_ID <= 0;
        muxSelector <= 0;
    end
end
endmodule