`timescale 1ns/1ns

// ============================================================
// CNN-CFU 모듈 단위 테스트벤치
// - MAC4, RELU, MAXPOOL2, CLRACC, RESCALE 각 연산 검증
// ============================================================
module cnn_cfu_tb;

    // ----------------------------------------------------------
    // Signals
    // ----------------------------------------------------------
    reg  [2:0]  cfu_op;
    reg  [31:0] rs1_data;
    reg  [31:0] rs2_data;
    wire [31:0] cfu_result;

    // ----------------------------------------------------------
    // DUT instantiation
    // ----------------------------------------------------------
    cnn_cfu uut (
        .cfu_op     (cfu_op),
        .rs1_data   (rs1_data),
        .rs2_data   (rs2_data),
        .cfu_result (cfu_result)
    );

    // ----------------------------------------------------------
    // Test tracking
    // ----------------------------------------------------------
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num   = 0;

    task check;
        input [31:0] expected;
        input [255:0] test_name;  // 32-char max
        begin
            test_num = test_num + 1;
            #1;  // wait for combinational settle
            if (cfu_result === expected) begin
                $display("[PASS] Test %0d: %0s | result=0x%08h", test_num, test_name, cfu_result);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %0s | expected=0x%08h, got=0x%08h", 
                         test_num, test_name, expected, cfu_result);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ----------------------------------------------------------
    // Test scenarios
    // ----------------------------------------------------------
    initial begin
        $display("============================================================");
        $display("  CNN-CFU Unit Test");
        $display("============================================================");
        $display("");

        // ======================================================
        // 1. MAC4 Tests (cfu_op = 3'b000)
        // ======================================================
        $display("--- MAC4 Tests ---");
        cfu_op = 3'b000;

        // TC1: 1*2 + 2*3 + 3*4 + 4*5 = 2+6+12+20 = 40
        rs1_data = {8'd4, 8'd3, 8'd2, 8'd1};
        rs2_data = {8'd5, 8'd4, 8'd3, 8'd2};
        check(32'd40, "MAC4: basic positive");

        // TC2: all ones → 1*1+1*1+1*1+1*1 = 4
        rs1_data = 32'h01010101;
        rs2_data = 32'h01010101;
        check(32'd4, "MAC4: all ones");

        // TC3: zeros → 0
        rs1_data = 32'h00000000;
        rs2_data = 32'h12345678;
        check(32'd0, "MAC4: zero input");

        // TC4: negative * positive → (-1)*2 + 0*0 + 0*0 + 0*0 = -2
        rs1_data = {8'd0, 8'd0, 8'd0, 8'hFF};  // [7:0]=0xFF=-1 (signed)
        rs2_data = {8'd0, 8'd0, 8'd0, 8'd2};
        check(32'hFFFFFFFE, "MAC4: neg*pos = -2");

        // TC5: all max positive → 127*127*4 = 64516
        rs1_data = 32'h7F7F7F7F;  // 127,127,127,127
        rs2_data = 32'h7F7F7F7F;
        check(32'd64516, "MAC4: max positive");

        // TC6: min * max → (-128)*127*4 = -65024
        rs1_data = 32'h80808080;  // -128,-128,-128,-128
        rs2_data = 32'h7F7F7F7F;  // 127,127,127,127
        check(-32'd65024, "MAC4: min*max");

        // TC7: mixed signs → (-1)*1 + 2*(-3) + 0*0 + 1*1 = -1-6+0+1 = -6
        rs1_data = {8'd1,  8'd0,  8'hFD, 8'hFF};  // bytes: -1, -3(=0xFD), 0, 1
        rs2_data = {8'd1,  8'd0,  8'd2,  8'd1};   // bytes: 1, 2, 0, 1
        // [7:0]: 0xFF*0x01 = (-1)*1 = -1
        // [15:8]: 0xFD*0x02 = (-3)*2 = -6
        // [23:16]: 0x00*0x00 = 0
        // [31:24]: 0x01*0x01 = 1
        // total = -1 + (-6) + 0 + 1 = -6
        check(-32'd6, "MAC4: mixed signs");

        $display("");

        // ======================================================
        // 2. RELU Tests (cfu_op = 3'b001)
        // ======================================================
        $display("--- RELU Tests ---");
        cfu_op = 3'b001;

        // TC1: positive → pass through
        rs1_data = 32'h00000042;
        rs2_data = 32'h00000000;  // unused
        check(32'h00000042, "RELU: positive(66)");

        // TC2: negative → 0
        rs1_data = 32'hFFFFFFBE;  // -66
        rs2_data = 32'h00000000;
        check(32'h00000000, "RELU: negative(-66)");

        // TC3: zero → 0
        rs1_data = 32'h00000000;
        rs2_data = 32'h00000000;
        check(32'h00000000, "RELU: zero");

        // TC4: INT32 max → pass through
        rs1_data = 32'h7FFFFFFF;
        rs2_data = 32'h00000000;
        check(32'h7FFFFFFF, "RELU: INT32_MAX");

        // TC5: INT32 min → 0
        rs1_data = 32'h80000000;
        rs2_data = 32'h00000000;
        check(32'h00000000, "RELU: INT32_MIN");

        // TC6: small positive (1)
        rs1_data = 32'h00000001;
        rs2_data = 32'h00000000;
        check(32'h00000001, "RELU: one");

        // TC7: -1
        rs1_data = 32'hFFFFFFFF;
        rs2_data = 32'h00000000;
        check(32'h00000000, "RELU: minus one");

        $display("");

        // ======================================================
        // 3. MAXPOOL2 Tests (cfu_op = 3'b010)
        // ======================================================
        $display("--- MAXPOOL2 Tests ---");
        cfu_op = 3'b010;

        // TC1: max(5, 10, 15, 3) = 15
        rs1_data = {16'h0000, 8'd10, 8'd5};   // a=5, b=10
        rs2_data = {16'h0000, 8'd3,  8'd15};  // c=15, d=3
        check(32'd15, "MAXPOOL2: max=15");

        // TC2: max(0, 0, 0, 0) = 0
        rs1_data = 32'h00000000;
        rs2_data = 32'h00000000;
        check(32'd0, "MAXPOOL2: all zeros");

        // TC3: max(255, 255, 255, 255) = 255
        rs1_data = {16'h0000, 8'hFF, 8'hFF};
        rs2_data = {16'h0000, 8'hFF, 8'hFF};
        check(32'd255, "MAXPOOL2: all max");

        // TC4: max(100, 200, 50, 150) = 200
        rs1_data = {16'h0000, 8'd200, 8'd100};  // a=100, b=200
        rs2_data = {16'h0000, 8'd150, 8'd50};   // c=50, d=150
        check(32'd200, "MAXPOOL2: max=200");

        // TC5: max(1, 2, 3, 4) = 4
        rs1_data = {16'h0000, 8'd2, 8'd1};
        rs2_data = {16'h0000, 8'd4, 8'd3};
        check(32'd4, "MAXPOOL2: max=4");

        // TC6: first element is max
        rs1_data = {16'h0000, 8'd10, 8'd250};
        rs2_data = {16'h0000, 8'd20, 8'd30};
        check(32'd250, "MAXPOOL2: first is max");

        $display("");

        // ======================================================
        // 4. CLRACC Tests (cfu_op = 3'b011)
        // ======================================================
        $display("--- CLRACC Tests ---");
        cfu_op = 3'b011;

        rs1_data = 32'hDEADBEEF;
        rs2_data = 32'hCAFEBABE;
        check(32'd0, "CLRACC: always zero");

        rs1_data = 32'hFFFFFFFF;
        rs2_data = 32'hFFFFFFFF;
        check(32'd0, "CLRACC: always zero 2");

        $display("");

        // ======================================================
        // 5. RESCALE Tests (cfu_op = 3'b100)
        // ======================================================
        $display("--- RESCALE Tests ---");
        cfu_op = 3'b100;

        // TC1: 2048, shift=5 → (2048+16)>>5 = 2064>>5 = 64
        rs1_data = 32'd2048;
        rs2_data = 32'd5;
        check(32'd64, "RESCALE: 2048>>5=64");

        // TC2: negative → clamp to 0
        rs1_data = 32'hFFFFFC00;  // -1024
        rs2_data = 32'd4;
        check(32'd0, "RESCALE: neg clamp=0");

        // TC3: overflow → clamp to 255
        rs1_data = 32'h00010000;  // 65536
        rs2_data = 32'd4;
        // (65536 + 8) >> 4 = 65544 >> 4 = 4096 > 255 → 255
        check(32'd255, "RESCALE: overflow clamp=255");

        // TC4: shift=0 → value itself, clamp check
        rs1_data = 32'd128;
        rs2_data = 32'd0;
        check(32'd128, "RESCALE: shift=0, val=128");

        // TC5: shift=0, val=255 → 255 (boundary)
        rs1_data = 32'd255;
        rs2_data = 32'd0;
        check(32'd255, "RESCALE: shift=0, val=255");

        // TC6: shift=0, val=256 → clamp 255
        rs1_data = 32'd256;
        rs2_data = 32'd0;
        check(32'd255, "RESCALE: shift=0, val=256 clamp");

        // TC7: 512, shift=2 → (512+2)>>2 = 514>>2 = 128
        rs1_data = 32'd512;
        rs2_data = 32'd2;
        check(32'd128, "RESCALE: 512>>2=128");

        // TC8: exact rounding → 7, shift=1 → (7+1)>>1 = 4
        rs1_data = 32'd7;
        rs2_data = 32'd1;
        check(32'd4, "RESCALE: 7>>1=4 (round)");

        // TC9: large negative → clamp 0
        rs1_data = 32'h80000000;  // INT32_MIN
        rs2_data = 32'd8;
        check(32'd0, "RESCALE: INT32_MIN clamp=0");

        $display("");

        // ======================================================
        // Summary
        // ======================================================
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
