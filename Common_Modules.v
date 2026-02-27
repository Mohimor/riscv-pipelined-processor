// ============================================
// Common_Modules.v - ماژول‌های مشترک بین تمام مراحل
// ============================================

module Adder (
    input wire signed [31:0] input1, 
    input wire signed [31:0] input2,
    output wire [31:0] result
);
assign result = input1 + input2;
endmodule

module Mux2x1_32Bits(
    output reg [31:0] result,
    input [31:0] input1,
    input [31:0] input2,
    input select
);
always @(*) begin
    if (select == 1'b0)
        result = input1;
    else
        result = input2;
end
endmodule

module Mux3x1_32Bits(
    output reg [31:0] result,
    input [31:0] input1,
    input [31:0] input2,
    input [31:0] input3,
    input [1:0] select
);
always @(*) begin
    case (select)
        2'b00: result = input1;
        2'b01: result = input2;
        2'b10: result = input3;
        default: result = 32'b0;
    endcase
end
endmodule

module Mux2x1_5Bits(
    output reg [4:0] result,
    input [4:0] input1,
    input [4:0] input2,
    input select
);
always @(*) begin
    if (select == 1'b0)
        result = input1;
    else
        result = input2;
end
endmodule

module Mux2x1_10Bits(
    output reg [9:0] result,
    input [9:0] input1,
    input [9:0] input2,
    input select
);
always @(*) begin
    if (select == 1'b0)
        result = input1;
    else
        result = input2;
end
endmodule