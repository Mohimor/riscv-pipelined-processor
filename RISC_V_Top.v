// ============================================
// RISC_V_Top.v - Top Level Module
// ============================================

module RISC_V_Top(
    input clock,
    input reset,
    output [31:0] pc_out,
    output [31:0] instruction_out,
    output [31:0] register_10_out
);

    wire [31:0] nextPC, readPC, PCPlus4IF, PCPlus4ID, PCPlus4EX, branchAddress;
    wire [31:0] instructionID, instructionIF;
    
    wire [31:0] registerData1ID, registerData2ID, registerData1EX, registerData2EX;
    wire [31:0] signExtendOutID, signExtendOutEX;
    
    wire [31:0] ALUData1, ALUData2, ALUData2Mux_1Out, ALUResultEX;
    wire [31:0] ALUResultMEM, ALUResultWB, memoryWriteDataMEM;
    wire [31:0] comparatorMux1Out, comparatorMux2Out;
    
    wire [31:0] memoryReadDataMEM, memoryReadDataWB, regWriteDataMEM;
    wire [31:0] shiftOut;
    
    wire [4:0] rs1EX, rs2EX, rdEX, regDstMuxOut, writeRegMEM, writeRegWB;
    wire [3:0] ALUOpID, ALUOpEX, ALUControl;
    wire [1:0] upperMux_sel, lowerMux_sel, comparatorMux1Selector, comparatorMux2Selector;
    
    wire RegDstID, branchID, MemReadID, MemtoRegID, MemWriteID, ALUSrcID, RegWriteID;
    wire RegWriteEX, MemtoRegEX, MemWriteEX, MemReadEX, ALUSrcEX, RegDstEX;
    wire RegWriteMEM, MemtoRegMEM, MemWriteMEM, MemReadMEM;
    wire RegWriteWB, MemtoRegWB;
    
    wire holdPC, holdIF_ID, hazardMuxSelector;
    wire PCMuxSel, equalFlag;
    wire overflow, zero;

    PC PCRegister(clock, nextPC, readPC, reset, holdPC);
    Adder PCAdder(readPC, 32'h00000004, PCPlus4IF);
    InstructionMemory instructionMemory(clock, readPC, instructionIF);
    Mux2x1_32Bits nextPCMux(nextPC, PCPlus4IF, branchAddress, PCMuxSel);
    IF_ID_reg IF_ID(clock, PCPlus4IF, instructionIF, instructionID, holdIF_ID, PCPlus4ID, PCMuxSel);
    and branchAndComparator(PCMuxSel, equalFlag, branchID);

    ControlUnit_RV controlUnit(
        instructionID[6:0],
        RegDstID, branchID, MemReadID, MemtoRegID, ALUOpID, 
        MemWriteID, ALUSrcID, RegWriteID, reset
    );
    
    RegisterFile_RV registerFile(
        clock,
        instructionID[19:15],
        instructionID[24:20],
        writeRegWB,
        regWriteDataMEM,
        RegWriteWB,
        registerData1ID,
        registerData2ID,
        reset
    );
    
    Comparator comparator(comparatorMux1Out, comparatorMux2Out, equalFlag);
    
    Mux3x1_32Bits comparatorMux1(
        comparatorMux1Out,
        registerData1ID,
        ALUResultMEM,
        regWriteDataMEM,
        comparatorMux1Selector
    );
    
    Mux3x1_32Bits comparatorMux2(
        comparatorMux2Out,
        registerData2ID,
        ALUResultMEM,
        regWriteDataMEM,
        comparatorMux2Selector
    );
    
    wire [2:0] imm_type;
    assign imm_type = (instructionID[6:0] == 7'b0000011) ? 3'b000 :
                      (instructionID[6:0] == 7'b0010011) ? 3'b000 :
                      (instructionID[6:0] == 7'b0100011) ? 3'b001 :
                      (instructionID[6:0] == 7'b1100011) ? 3'b010 :
                      3'b000;
    
    SignExtend_RV signExtend(instructionID, imm_type, signExtendOutID);
    
    ShiftLeft2 shiftLeft2(shiftOut, signExtendOutID);
    Adder branchAdder(branchAddress, PCPlus4ID, shiftOut);
    
    HazardDetectionUnit_RV hazardUnit(
        MemReadEX,
        MemReadMEM,
        rdEX,
        instructionID,
        holdPC,
        holdIF_ID,
        hazardMuxSelector
    );
    
    wire [9:0] controlSignalsID;
    Mux2x1_10Bits ID_EXRegMux(
        controlSignalsID,
        {RegWriteID, MemtoRegID, MemWriteID, MemReadID, ALUSrcID, ALUOpID, RegDstID},
        10'b0000000000,
        hazardMuxSelector
    );
    
    ID_EX_reg_RV ID_EX(
        clock,
        RegWriteID, MemtoRegID, MemWriteID, MemReadID, ALUSrcID, ALUOpID, RegDstID,
        PCPlus4ID,
        registerData1ID,
        registerData2ID,
        signExtendOutID,
        instructionID[19:15],
        instructionID[24:20],
        instructionID[11:7],
        PCPlus4EX,
        registerData1EX,
        registerData2EX,
        signExtendOutEX,
        rs1EX,
        rs2EX,
        rdEX,
        RegWriteEX,
        MemtoRegEX,
        MemWriteEX,
        MemReadEX,
        ALUSrcEX,
        ALUOpEX,
        RegDstEX
    );

    Mux3x1_32Bits ALUData1Mux(
        ALUData1,
        registerData1EX,
        regWriteDataMEM,
        ALUResultMEM,
        upperMux_sel
    );
    
    Mux3x1_32Bits ALUData2Mux_1(
        ALUData2Mux_1Out,
        registerData2EX,
        regWriteDataMEM,
        ALUResultMEM,
        lowerMux_sel
    );
    
    Mux2x1_32Bits ALUData2Mux_2(
        ALUData2,
        ALUData2Mux_1Out,
        signExtendOutEX,
        ALUSrcEX
    );
    
    ALUControl_RV aluControl(
        ALUOpEX,
        signExtendOutEX[31:25],
        signExtendOutEX[14:12],
        ALUControl
    );
    
    ALU32Bit_RV ALU(
        ALUData1,
        ALUData2,
        ALUControl,
        signExtendOutEX[24:20],
        reset,
        overflow,
        zero,
        ALUResultEX
    );
    
    Mux2x1_5Bits regDstMux(
        regDstMuxOut,
        rs2EX,
        rdEX,
        RegDstEX
    );
    
    EX_MemReg_RV EX_MEM(
        clock,
        RegWriteEX,
        MemtoRegEX,
        MemWriteEX,
        MemReadEX,
        ALUResultEX,
        ALUData2Mux_1Out,
        regDstMuxOut,
        RegWriteMEM,
        MemtoRegMEM,
        MemWriteMEM,
        MemReadMEM,
        ALUResultMEM,
        memoryWriteDataMEM,
        writeRegMEM
    );
    
    ForwardingUnit_RV forwardingUnit(
        RegWriteMEM,
        writeRegMEM,
        RegWriteWB,
        writeRegWB,
        rs1EX,
        rs2EX,
        upperMux_sel,
        lowerMux_sel,
        comparatorMux1Selector,
        comparatorMux2Selector
    );

    DataMemory_RV dataMemory(
        .clock(clock),
        .memoryWrite(MemWriteMEM),
        .memoryRead(MemReadMEM),
        .address(ALUResultMEM),
        .writeData(memoryWriteDataMEM),
        .readData(memoryReadDataMEM),
        .reset(reset)
    );
    
    Mem_WbReg_RV MEM_WB(
        clock,
        RegWriteMEM,
        MemtoRegMEM,
        ALUResultMEM,
        memoryReadDataMEM,
        writeRegMEM,
        RegWriteWB,
        MemtoRegWB,
        memoryReadDataWB,
        ALUResultWB,
        writeRegWB
    );

    Mux2x1_32Bits writeBackMux(
        regWriteDataMEM,
        ALUResultWB,
        memoryReadDataWB,
        MemtoRegWB
    );
    
    assign pc_out = readPC;
    assign instruction_out = instructionIF;
    assign register_10_out = registerFile.registers[10];

endmodule