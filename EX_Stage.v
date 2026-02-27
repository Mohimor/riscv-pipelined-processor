// ============================================
// EX_Stage.v - Execution Stage
// ============================================

module ID_EX_reg_RV (
    input wire clock,
    input wire registerWrite,
    input wire memoryToRegister,
    input wire memoryWrite,
    input wire memoryRead,
    input wire ALUSrc,
    input wire [3:0] ALUOp,
    input wire registerDestination,
    input wire [31:0] PCplus4,
    input wire [31:0] data1Input,
    input wire [31:0] data2Input,
    input wire [31:0] signExtendResultInput,
    input wire [4:0] rs1Input,
    input wire [4:0] rs2Input,
    input wire [4:0] rdInput,
    output reg [31:0] PCplus4out,
    output reg [31:0] data1Output,
    output reg [31:0] data2Output,
    output reg [31:0] signExtendResultOutput,
    output reg [4:0] rs1Out,
    output reg [4:0] rs2Out,
    output reg [4:0] rdOut,
    output reg registerWriteOutput,
    output reg memoryToRegisterOutput,
    output reg memoryWriteOutput,
    output reg memoryReadOutput,
    output reg ALUSrcOut,
    output reg [3:0] ALUOpOut,
    output reg registerDestinationOut
);
always @(posedge clock) begin
    PCplus4out <= PCplus4;
    data1Output <= data1Input;
    data2Output <= data2Input;
    signExtendResultOutput <= signExtendResultInput;
    rs1Out <= rs1Input;
    rs2Out <= rs2Input;
    rdOut <= rdInput;
    registerWriteOutput <= registerWrite;
    memoryToRegisterOutput <= memoryToRegister;
    memoryWriteOutput <= memoryWrite;
    memoryReadOutput <= memoryRead;
    ALUSrcOut <= ALUSrc;
    ALUOpOut <= ALUOp;
    registerDestinationOut <= registerDestination;
end
endmodule

module ALU32Bit_RV(
    input wire signed [31:0] data1,
    input wire signed [31:0] data2,
    input wire [3:0] ALUControl,
    input wire [4:0] shiftAmount,
    input wire reset,
    output reg overflow,
    output reg zero,
    output reg signed [31:0] result
);
wire [31:0] neg_data2;
assign neg_data2 = -data2;

always @(posedge reset) begin
    zero <= 1'b0;
end

always @(*) begin
    case (ALUControl)
        4'b0000: begin
            result = data1 + data2;
            overflow = (data1[31] == data2[31] && result[31] != data1[31]) ? 1'b1 : 1'b0;
        end
        4'b0001: begin
            result = data1 - data2;
            overflow = (data1[31] != data2[31] && result[31] != data1[31]) ? 1'b1 : 1'b0;
        end
        4'b1000: begin
            result = (data1 < data2) ? 32'd1 : 32'd0;
            overflow = 1'b0;
        end
        default: begin
            result = 32'bx;
            overflow = 1'bx;
        end
    endcase
    zero = (result == 0) ? 1'b1 : 1'b0;
end
endmodule

module ALUControl_RV(
    input [3:0] ALUOp,
    input [6:0] funct7,
    input [2:0] funct3,
    output reg [3:0] ALUControl
);
always @(*) begin
    case (ALUOp)
        4'b0000: ALUControl = 4'b0000;
        4'b0001: ALUControl = 4'b0001;
        4'b0101: ALUControl = 4'b1000;
        4'b0010: begin
            case ({funct7, funct3})
                10'b0000000_000: ALUControl = 4'b0000;
                10'b0100000_000: ALUControl = 4'b0001;
                10'b0000000_010: ALUControl = 4'b1000;
                default: ALUControl = 4'bxxxx;
            endcase
        end
        default: ALUControl = 4'bxxxx;
    endcase
end
endmodule

module ForwardingUnit_RV (
    input EX_MemRegwrite,
    input [4:0] EX_MemWriteReg,
    input Mem_WbRegwrite,
    input [4:0] Mem_WbWriteReg,
    input [4:0] ID_Ex_Rs1,
    input [4:0] ID_Ex_Rs2,
    output reg [1:0] upperMux_sel,
    output reg [1:0] lowerMux_sel,
    output reg [1:0] comparatorMux1Selector,
    output reg [1:0] comparatorMux2Selector
);
always @(*) begin
    upperMux_sel = 2'b00;
    lowerMux_sel = 2'b00;
    comparatorMux1Selector = 2'b00;
    comparatorMux2Selector = 2'b00;
    
    if (EX_MemRegwrite && EX_MemWriteReg != 0) begin
        if (EX_MemWriteReg == ID_Ex_Rs1) begin
            upperMux_sel = 2'b10;
            comparatorMux1Selector = 2'b01;
        end
        if (EX_MemWriteReg == ID_Ex_Rs2) begin
            lowerMux_sel = 2'b10;
            comparatorMux2Selector = 2'b01;
        end
    end
    
    if (Mem_WbRegwrite && Mem_WbWriteReg != 0) begin
        if ((Mem_WbWriteReg == ID_Ex_Rs1) && !(EX_MemRegwrite && EX_MemWriteReg == ID_Ex_Rs1)) begin
            upperMux_sel = 2'b01;
            comparatorMux1Selector = 2'b10;
        end
        if ((Mem_WbWriteReg == ID_Ex_Rs2) && !(EX_MemRegwrite && EX_MemWriteReg == ID_Ex_Rs2)) begin
            lowerMux_sel = 2'b01;
            comparatorMux2Selector = 2'b10;
        end
    end
end
endmodule