`timescale 1ns/1ns

// ============================================================
// RV32I System with custom IMEM/DMEM sizes for Conv1 E2E Test
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

    // Data Memory (32KB = 8192 words)
    // Linked to address space [0x00008000 - 0x0000FFFF]
    reg [31:0] dmem [0:8191];
    
    // Address decoding: subtract 0x8000 offset (0x2000 words)
    wire [12:0] daddr = MemAddr[15:2] - 14'h2000;

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
// Conv1 End-to-End Testbench
// ============================================================
module conv1_e2e_tb;

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
        $display("  Conv1 End-to-End RTL Verification");
        $display("============================================================");
        $display("");

        // Reset
        reset = 1;
        #20;
        reset = 0;

        $display("[INFO] Simulation started. Running Conv1 layer...");

        // Wait for CPU to halt or reach max cycles (500,000)
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
                // Timeout after 500,000 cycles
                repeat (500000) @(posedge clk);
                $display("[ERROR] Simulation TIMEOUT after 500,000 cycles!");
                disable sim_block;
            end
        join

        // Wait a couple more cycles
        #20;

        $display("");
        $display("--- Verification Results ---");
        $display("Total Cycles: %0d", cycle_count);
        $display("Status Value (dmem[0]): 0x%08h", uut.dmem[0]);
        $display("");

        if (uut.dmem[0] === 32'h12345678) begin
            $display("============================================================");
            $display("  *** CONV1 E2E VERIFICATION PASSED ***");
            $display("  RTL CFU matching PyTorch Golden outputs perfectly!");
            $display("============================================================");
        end else if (uut.dmem[0] === 32'hDEADBEEF) begin
            $display("============================================================");
            $display("  *** CONV1 E2E VERIFICATION FAILED ***");
            $display("  Output values did not match Golden reference.");
            $display("============================================================");
        end else begin
            $display("============================================================");
            $display("  *** CONV1 E2E VERIFICATION FAILED (UNKNOWN STATUS) ***");
            $display("  Status register remains unwritten or in error state.");
            $display("============================================================");
        end

        $finish;
    end

endmodule
