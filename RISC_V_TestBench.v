// ============================================
// RISC_V_TestBench.v - TestBench Module
// ============================================

module RISC_V_TestBench();

    reg clock;
    reg reset;
    wire [31:0] pc_out;
    wire [31:0] instruction_out;
    wire [31:0] register_10_out;

    RISC_V_Top riscv_top(
        .clock(clock),
        .reset(reset),
        .pc_out(pc_out),
        .instruction_out(instruction_out),
        .register_10_out(register_10_out)
    );

    initial begin
        $dumpfile("RISC_V_TestBench.vcd");
        $dumpvars(0, RISC_V_TestBench);
        $display("==================================================");
        $display("RISC-V Pipeline Processor Simulation Started");
        $display("==================================================");
    end

    always #100 clock = ~clock;

    initial begin
        clock = 0;
        reset = 1;
        $display("[System] Reset asserted");
        #200 reset = 0;
        $display("[System] Reset deasserted - Starting execution");
        
        #20000;
        $display("==================================================");
        $display("Simulation Complete");
        $display("==================================================");
        $finish;
    end

    always @(posedge clock) begin
        #50;
        $display("----------------------------------------");
        $display("Time: %0t | PC: %h | Instruction: %h", $time, pc_out, instruction_out);
        $display("----------------------------------------");
    end

    always @(posedge clock) begin
        if ($time > 10000) begin
            $display("\n=== Fibonacci Sequence Progress ===");
            $display("x10 (F10) = %d", register_10_out);
            $display("===================================\n");
        end
    end

endmodule