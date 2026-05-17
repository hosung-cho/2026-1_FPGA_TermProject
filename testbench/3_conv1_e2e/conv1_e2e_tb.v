`timescale 1ns/1ns

// ============================================================
// Conv1 E2E 통합 테스트벤치
// - 6개 필터의 Conv1 출력 1 픽셀을 RTL에서 계산하고
//   Python 레퍼런스와 비교
// ============================================================
module conv1_e2e_tb;

    reg clk, reset;

    RV32I_CNN_TestSystem uut (
        .clk    (clk),
        .reset  (reset)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num   = 0;

    task check_dmem;
        input [9:0]   word_addr;
        input [31:0]  expected;
        input [255:0] test_name;
        reg [31:0] actual;
        begin
            test_num = test_num + 1;
            actual = uut.dmem[word_addr];
            if (actual === expected) begin
                $display("[PASS] Test %0d: %0s | dmem[%0d]=0x%08h",
                         test_num, test_name, word_addr, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %0s | dmem[%0d] expected=0x%08h, got=0x%08h",
                         test_num, test_name, word_addr, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $display("============================================================");
        $display("  Conv1 E2E RTL Test (6 filters, 1 pixel)");
        $display("============================================================");
        $display("");

        reset = 1;
        #25;
        reset = 0;

        // Wait for program halt (192 instructions + some margin)
        repeat (250) begin
            @(posedge clk);
            if (uut.is_halted) begin
                // Wait a couple more cycles for final store
                @(posedge clk);
                @(posedge clk);
                
                $display("[INFO] CPU halted at PC=0x%08h", uut.pc);
                $display("");
                $display("--- Checking Conv1 Output ---");

                // Expected values from Python reference
                check_dmem(64, 32'h00000000, "Filter 0: clamp_neg");
                check_dmem(65, 32'h0000003D, "Filter 1: val=61");
                check_dmem(66, 32'h000000FF, "Filter 2: clamp_255");
                check_dmem(67, 32'h000000FF, "Filter 3: clamp_255");
                check_dmem(68, 32'h00000000, "Filter 4: clamp_neg");
                check_dmem(69, 32'h0000003F, "Filter 5: val=63");

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
        end

        $display("[ERROR] CPU did not halt within expected cycles!");
        $finish;
    end

endmodule
