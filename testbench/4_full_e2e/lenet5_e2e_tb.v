`timescale 1ns/1ns

// ============================================================
// RV32I System with custom IMEM/DMEM sizes for LeNet-5 E2E Test
// ============================================================
module RV32I_CNN_TestSystem(
    input         clk,
    input         reset
);

    wire [31:0] pc;
    wire [31:0] inst;
    wire        MemWrite;
    wire [31:0] MemAddr;
    wire [31:0] MemWData;
    wire [3:0]  ByteEnable;
    wire [31:0] MemRData;

    wire is_halted = (inst == 32'h0000006f);  // JAL x0, 0 (infinite loop = halt)

    // CPU instantiation
    rv32i_cpu icpu (
        .clk        (clk),
        .reset      (reset),
        .pc         (pc),
        .inst       (inst),
        .MemWrite   (MemWrite),
        .MemAddr    (MemAddr),
        .MemWData   (MemWData),
        .ByteEnable (ByteEnable),
        .MemRData   (MemRData)
    );

    // Instruction Memory (16KB = 4096 words)
    reg [31:0] imem [0:4095];
    assign inst = imem[pc[13:2]];

    // Data Memory (64KB = 16384 words)
    // Linked to address space [0x00008000 - 0x00017FFF]
    reg [31:0] dmem [0:16383];
    
    // Address decoding: subtract 0x8000 offset (0x2000 words)
    // 16384 words requires a 14-bit index
    wire [13:0] daddr = MemAddr[15:2] - 14'h2000;

    assign MemRData = dmem[daddr];

    // Byte-enable write
    wire [3:0] we = MemWrite ? ByteEnable : 4'b0000;
    always @(posedge clk) begin
        if (we[0]) dmem[daddr][ 7: 0] <= MemWData[ 7: 0];
        if (we[1]) dmem[daddr][15: 8] <= MemWData[15: 8];
        if (we[2]) dmem[daddr][23:16] <= MemWData[23:16];
        if (we[3]) dmem[daddr][31:24] <= MemWData[31:24];
    end

    // Load programs
    initial begin
        $readmemh("imem.hex", imem);
        $readmemh("dmem.hex", dmem);
    end

endmodule


// ============================================================
// LeNet-5 Full Network End-to-End Testbench
// ============================================================
module lenet5_e2e_tb;

    reg clk, reset;

    RV32I_CNN_TestSystem uut (
        .clk    (clk),
        .reset  (reset)
    );

    // Clock generation: 10ns period (100MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    integer cycle_count = 0;
    always @(posedge clk) begin
        if (!reset) cycle_count = cycle_count + 1;
    end

    initial begin
        $display("============================================================");
        $display("  LeNet-5 Full Network End-to-End RTL Verification");
        $display("  [Conv1 -> Pool1 -> Conv2 -> Pool2 -> FC1 -> FC2 -> FC3]");
        $display("============================================================");
        $display("");

        // Reset
        reset = 1;
        #20;
        reset = 0;

        $display("[INFO] Simulation started. Running LeNet-5 inference on MNIST Image 0 (label=7)...");

        // Wait for CPU to halt or reach max cycles (5,000,000)
        fork : sim_block
            begin
                // Wait for halt
                while (!uut.is_halted) begin
                    @(posedge clk);
                end
                $display("[INFO] CPU halted at PC=0x%08h", uut.pc);
                disable sim_block;
            end
            begin
                // Timeout after 5,000,000 cycles
                repeat (5000000) @(posedge clk);
                $display("[ERROR] Simulation TIMEOUT after 5,000,000 cycles!");
                disable sim_block;
            end
        join

        // Wait a couple more cycles
        #20;

        $display("");
        $display("--- Verification Results ---");
        $display("Total Cycles: %0d", cycle_count);
        $display("Status Value (dmem[0]): 0x%08h", uut.dmem[0]);
        $display("Predicted Label (dmem[1]): %0d", uut.dmem[1]);
        $display("");
        $display("--- Raw Class Scores (dmem[2] ~ dmem[11]) ---");
        $display("Class 0: %d", $signed(uut.dmem[2]));
        $display("Class 1: %d", $signed(uut.dmem[3]));
        $display("Class 2: %d", $signed(uut.dmem[4]));
        $display("Class 3: %d", $signed(uut.dmem[5]));
        $display("Class 4: %d", $signed(uut.dmem[6]));
        $display("Class 5: %d", $signed(uut.dmem[7]));
        $display("Class 6: %d", $signed(uut.dmem[8]));
        $display("Class 7: %d", $signed(uut.dmem[9]));
        $display("Class 8: %d", $signed(uut.dmem[10]));
        $display("Class 9: %d", $signed(uut.dmem[11]));
        $display("");

        if (uut.dmem[0] === 32'h12345678) begin
            $display("============================================================");
            $display("  *** LENET5 FULL E2E VERIFICATION PASSED ***");
            $display("  RTL CFU matching PyTorch Golden outputs perfectly!");
            $display("  Predicted Label: %0d (Correct!)", uut.dmem[1]);
            $display("============================================================");
        end else if (uut.dmem[0] === 32'hDEADBEEF) begin
            $display("============================================================");
            $display("  *** LENET5 FULL E2E VERIFICATION FAILED ***");
            $display("  Output values did not match Golden reference.");
            $display("  Predicted Label: %0d (Expected: 7)", uut.dmem[1]);
            $display("============================================================");
        end else begin
            $display("============================================================");
            $display("  *** LENET5 FULL E2E VERIFICATION FAILED (UNKNOWN STATUS) ***");
            $display("  Status register remains unwritten or in error state.");
            $display("============================================================");
        end

        $finish;
    end

endmodule
