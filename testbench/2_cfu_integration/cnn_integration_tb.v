`timescale 1ns/1ns

// ============================================================
// CNN-CFU 통합 테스트 시스템
// - 내부 메모리 포함 (테스트벤치용)
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

    // Instruction Memory (4KB = 1024 words)
    reg [31:0] imem [0:1023];
    assign inst = imem[pc[11:2]];

    // Data Memory (4KB = 1024 words)
    reg [31:0] dmem [0:1023];
    wire [9:0] daddr = MemAddr[11:2];

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
// 통합 테스트벤치
// ============================================================
module cnn_integration_tb;

    reg clk, reset;

    RV32I_CNN_TestSystem uut (
        .clk    (clk),
        .reset  (reset)
    );

    // Clock generation: 10ns period (100MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Register file alias for easy checking
    wire [31:0] x10 = uut.icpu.i_datapath.i_regfile.mem[10];
    wire [31:0] x11 = uut.icpu.i_datapath.i_regfile.mem[11];
    wire [31:0] x12 = uut.icpu.i_datapath.i_regfile.mem[12];
    wire [31:0] x13 = uut.icpu.i_datapath.i_regfile.mem[13];
    wire [31:0] x14 = uut.icpu.i_datapath.i_regfile.mem[14];
    wire [31:0] x15 = uut.icpu.i_datapath.i_regfile.mem[15];
    wire [31:0] x16 = uut.icpu.i_datapath.i_regfile.mem[16];
    wire [31:0] x17 = uut.icpu.i_datapath.i_regfile.mem[17];

    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num   = 0;

    task check_reg;
        input [4:0]   reg_num;
        input [31:0]  expected;
        input [255:0] test_name;
        reg [31:0] actual;
        begin
            test_num = test_num + 1;
            actual = uut.icpu.i_datapath.i_regfile.mem[reg_num];
            if (actual === expected) begin
                $display("[PASS] Test %0d: %0s | x%0d=0x%08h", test_num, test_name, reg_num, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %0s | x%0d expected=0x%08h, got=0x%08h",
                         test_num, test_name, reg_num, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $display("============================================================");
        $display("  CNN-CFU Integration Test (Single-Cycle Core)");
        $display("============================================================");
        $display("");

        // Reset
        reset = 1;
        #20;
        reset = 0;

        // Wait for program to reach halt (JAL x0, 0)
        // Max 200 cycles
        repeat (200) begin
            @(posedge clk);
            if (uut.is_halted) begin
                $display("[INFO] CPU halted at PC=0x%08h, cycle=%0t", uut.pc, $time);
            end
        end

        // Wait one more cycle for final write-back
        @(posedge clk);

        $display("");
        $display("--- Checking Results ---");

        // Expected results from the test program (see imem.hex comments):
        // x10 = MAC4({4,3,2,1}, {5,4,3,2}) = 4*5+3*4+2*3+1*2 = 20+12+6+2 = 40
        check_reg(10, 32'd40, "MAC4 result");

        // x11 = RELU(x10) = relu(40) = 40
        check_reg(11, 32'd40, "RELU positive");

        // x12 = RELU(-1) = 0  (x12 was loaded with -1, then relu'd)
        check_reg(12, 32'd0, "RELU negative");

        // x13 = MAXPOOL2({10,5}, {3,15}) = max(5,10,15,3) = 15
        check_reg(13, 32'd15, "MAXPOOL2 result");

        // x14 = CLRACC = 0
        check_reg(14, 32'd0, "CLRACC result");

        // x15 = RESCALE(2048, 5) = 64
        check_reg(15, 32'd64, "RESCALE result");

        // x16 = MAC4 + ADD accumulation test
        // dot4({1,1,1,1},{2,2,2,2}) = 8, then ADD to 0 → 8
        // + dot4({3,3,3,3},{1,1,1,1}) = 12, ADD → 20
        check_reg(16, 32'd20, "MAC4+ADD accumulate");

        // x17 = full pipeline: MAC4 → RESCALE → RELU
        // dot4({10,20,30,40},{1,1,1,1}) = 100
        // rescale(100, 2) = (100+2)>>2 = 25
        // relu(25) = 25
        check_reg(17, 32'd25, "MAC4->RESCALE->RELU chain");

        $display("");
        $display("============================================================");
        $display("  TOTAL: %0d tests | PASS: %0d | FAIL: %0d",
                 pass_count + fail_count, pass_count, fail_count);
        if (fail_count == 0)
            $display("  *** ALL TESTS PASSED ***");
        else
            $display("  *** SOME TESTS FAILED ***");
        $display("============================================================");

        $finish;
    end

endmodule
