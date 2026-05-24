`timescale 1 ns / 1 ns
// ======================================================================
// 명령어 메모리 (Instruction Memory)
// 컴파일된 어셈블리 명령어들(.hex)이 들어가는 ROM(롬) 역할을 합니다.
// CPU의 PC(프로그램 카운터) 주소를 받아, 1클럭 내에 해당 주소의 명령어를 즉시 출력합니다.
// ======================================================================
module inst_memory #(
    parameter DEPTH = 16384
) (
    input               clock,
    input               enable,
    input      [13:0]   address,
    output reg [31:0]   instruction
);

    // Instruction memory array
    reg [31:0] mem [0:DEPTH-1];
    
    integer i;

    // Initialize instruction memory
    initial begin
        // Initialize all memory to NOP (addi x0, x0, 0)
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = 32'h00000013;  // NOP
        end
        
        // Load instructions from external file by default.
        $readmemh("imem.hex", mem);

        // ========================================
        // 파이프라인 CPU 테스트 벤치 (Built-in Test Suite)
        // 아래 코드는 파이프라인의 데이터 해저드, 분기(제어) 해저드, 포워딩 기능 등이
        // 정상 동작하는지 검증하기 위해 미리 하드코딩해둔 어셈블리 명령어 묶음들입니다.
        // ========================================
        
        // Built-in tests are disabled by default for external HEX-based programs.
        // To use built-in tests, define INTERNAL_TEST_SELECT and TEST_SELECT.
        `ifdef INTERNAL_TEST_SELECT
            case (`TEST_SELECT)
                // ========================================
                // Test 1: Basic Pipeline Test - No Hazards
                // All operations use independent registers (no dependencies)
                // Tests basic pipeline functionality without any hazards
                // Expected Results:
                //   x10 = 10, x11 = 20, x12 = 30, x13 = 40, x14 = 50
                //   mem[0] = 10, mem[4] = 20, mem[8] = 30, mem[12] = 40, mem[16] = 50
                // ========================================
                1: begin
                    mem[0] = 32'h00a00513;  // addi  x10, x0, 10      ; x10 = 10
                    mem[1] = 32'h01400593;  // addi  x11, x0, 20      ; x11 = 20
                    mem[2] = 32'h01e00613;  // addi  x12, x0, 30      ; x12 = 30
                    mem[3] = 32'h02800693;  // addi  x13, x0, 40      ; x13 = 40
                    mem[4] = 32'h03200713;  // addi  x14, x0, 50      ; x14 = 50
                    mem[5] = 32'h00a02023;  // sw    x10, 0(x0)       ; mem[0] = 10
                    mem[6] = 32'h00b02223;  // sw    x11, 4(x0)       ; mem[4] = 20
                    mem[7] = 32'h00c02423;  // sw    x12, 8(x0)       ; mem[8] = 30
                    mem[8] = 32'h00d02623;  // sw    x13, 12(x0)      ; mem[12] = 40
                    mem[9] = 32'h00e02823;  // sw    x14, 16(x0)      ; mem[16] = 50
                    mem[10] = 32'h0000006f; // jal   x0, 0            ; halt
                    $display("Test 1: Basic Pipeline Test - No Hazards Loaded");
                    $display("Expected: mem[0]=10, mem[4]=20, mem[8]=30, mem[12]=40, mem[16]=50");
                end
                
                // ========================================
                // Test 2: Pipeline Efficiency Test - Independent Instructions
                // All operations are independent (no dependencies)
                // Tests maximum pipeline throughput without hazards
                // Expected Results:
                //   mem[0-36] = sequential values 1-10
                // ========================================
                2: begin
                    mem[0] = 32'h00100513;  // addi  x10, x0, 1       ; x10 = 1
                    mem[1] = 32'h00200593;  // addi  x11, x0, 2       ; x11 = 2
                    mem[2] = 32'h00300613;  // addi  x12, x0, 3       ; x12 = 3
                    mem[3] = 32'h00400693;  // addi  x13, x0, 4       ; x13 = 4
                    mem[4] = 32'h00500713;  // addi  x14, x0, 5       ; x14 = 5
                    mem[5] = 32'h00600793;  // addi  x15, x0, 6       ; x15 = 6
                    mem[6] = 32'h00700813;  // addi  x16, x0, 7       ; x16 = 7
                    mem[7] = 32'h00800893;  // addi  x17, x0, 8       ; x17 = 8
                    mem[8] = 32'h00900913;  // addi  x18, x0, 9       ; x18 = 9
                    mem[9] = 32'h00a00993;  // addi  x19, x0, 10      ; x19 = 10
                    mem[10] = 32'h00a02023; // sw    x10, 0(x0)       ; mem[0] = 1
                    mem[11] = 32'h00b02223; // sw    x11, 4(x0)       ; mem[4] = 2
                    mem[12] = 32'h00c02423; // sw    x12, 8(x0)       ; mem[8] = 3
                    mem[13] = 32'h00d02623; // sw    x13, 12(x0)      ; mem[12] = 4
                    mem[14] = 32'h00e02823; // sw    x14, 16(x0)      ; mem[16] = 5
                    mem[15] = 32'h00f02a23; // sw    x15, 20(x0)      ; mem[20] = 6
                    mem[16] = 32'h01002c23; // sw    x16, 24(x0)      ; mem[24] = 7
                    mem[17] = 32'h01102e23; // sw    x17, 28(x0)      ; mem[28] = 8
                    mem[18] = 32'h03202023; // sw    x18, 32(x0)      ; mem[32] = 9
                    mem[19] = 32'h03302223; // sw    x19, 36(x0)      ; mem[36] = 10
                    mem[20] = 32'h0000006f; // jal   x0, 0            ; halt
                    $display("Test 2: Pipeline Efficiency Test - Independent Instructions Loaded");
                    $display("Expected: mem[0]=1, mem[4]=2, ..., mem[36]=10");
                    $display("Should execute with maximum pipeline efficiency (CPI close to 1)");
                end
                
                // ========================================
                // Test 3: Data Hazard - Forwarding Test
                // Tests EX-EX forwarding and MEM-EX forwarding
                // Expected Results:
                //   x10 = 10, x11 = 20, x12 = 30, x13 = 40, x14 = 70, x15 = 100
                //   mem[0] = 70, mem[4] = 100
                // ========================================
                3: begin
                    mem[0] = 32'h00a00513;  // addi  x10, x0, 10      ; x10 = 10
                    mem[1] = 32'h00a50593;  // addi  x11, x10, 10     ; x11 = 20 (needs x10, EX-EX forward)
                    mem[2] = 32'h00a58613;  // addi  x12, x11, 10     ; x12 = 30 (needs x11, EX-EX forward)
                    mem[3] = 32'h00a60693;  // addi  x13, x12, 10     ; x13 = 40 (needs x12, EX-EX forward)
                    mem[4] = 32'h00b60733;  // add   x14, x12, x11    ; x14 = 30+20=50, but x12=30, x11=20 -> 50
                    mem[5] = 32'h01450713;  // addi  x14, x10, 20     ; x14 = 10+20=30, but needs MEM-EX forward for x10
                    mem[6] = 32'h02658733;  // add   x14, x11, x6     ; x14 = 20+0=20 (x6=0 by default)
                    mem[7] = 32'h00c58733;  // add   x14, x11, x12    ; x14 = 20+30=50 (MEM-EX forward)
                    mem[8] = 32'h00d60733;  // add   x14, x12, x13    ; x14 = 30+40=70 (MEM-EX forward)
                    mem[9] = 32'h00e02023;  // sw    x14, 0(x0)       ; mem[0] = 70
                    mem[10] = 32'h00b687b3; // add   x15, x13, x11    ; x15 = 40+20=60 (MEM-EX forward)
                    mem[11] = 32'h00a787b3; // add   x15, x15, x10    ; x15 = 60+10=70 (EX-EX forward)
                    mem[12] = 32'h01e78793; // addi  x15, x15, 30     ; x15 = 70+30=100 (EX-EX forward)
                    mem[13] = 32'h00f02223; // sw    x15, 4(x0)       ; mem[4] = 100
                    mem[14] = 32'h0000006f; // jal   x0, 0            ; halt
                    $display("Test 3: Data Hazard - Forwarding Test Loaded");
                    $display("Expected: mem[0]=70, mem[4]=100");
                end
                
                // ========================================
                // Test 4: Load-Use Hazard - Stall Test
                // Tests load-use hazard detection and stall insertion
                // Expected Results:
                //   mem[0] = 100, mem[4] = 150, mem[8] = 175
                // Pipeline should insert 1-cycle stall after load
                // ========================================
                4: begin
                    mem[0] = 32'h06400513;  // addi  x10, x0, 100     ; x10 = 100
                    mem[1] = 32'h00a02023;  // sw    x10, 0(x0)       ; mem[0] = 100
                    mem[2] = 32'h00002583;  // lw    x11, 0(x0)       ; x11 = 100 (load from mem[0])
                    mem[3] = 32'h03200613;  // addi  x12, x0, 50      ; x12 = 50 (should be inserted as NOP if stall)
                    mem[4] = 32'h00b60633;  // add   x12, x12, x11    ; x12 = 50+100=150 (load-use hazard, stall needed)
                    mem[5] = 32'h00c02223;  // sw    x12, 4(x0)       ; mem[4] = 150
                    mem[6] = 32'h00402683;  // lw    x13, 4(x0)       ; x13 = 150 (load from mem[4])
                    mem[7] = 32'h01900513;  // addi  x10, x0, 25      ; x10 = 25
                    mem[8] = 32'h00d506b3;  // add   x13, x10, x13    ; x13 = 25+150=175 (load-use hazard, stall needed)
                    mem[9] = 32'h00d02423;  // sw    x13, 8(x0)       ; mem[8] = 175
                    mem[10] = 32'h0000006f; // jal   x0, 0            ; halt
                    $display("Test 4: Load-Use Hazard - Stall Test Loaded");
                    $display("Expected: mem[0]=100, mem[4]=150, mem[8]=175");
                    $display("Pipeline should insert stalls after lw instructions");
                end
                
                // ========================================
                // Test 5: Branch Hazard - Flush Test
                // Tests load-use hazard detection and stall insertion
                // Expected Results:
                //   mem[0] = 100, mem[4] = 150, mem[8] = 175
                // Pipeline should insert 1-cycle stall after load
                // ========================================
                2: begin
                    mem[0] = 32'h06400513;  // addi  x10, x0, 100     ; x10 = 100
                    mem[1] = 32'h00a02023;  // sw    x10, 0(x0)       ; mem[0] = 100
                    mem[2] = 32'h00002583;  // lw    x11, 0(x0)       ; x11 = 100 (load from mem[0])
                    mem[3] = 32'h03200613;  // addi  x12, x0, 50      ; x12 = 50 (should be inserted as NOP if stall)
                    mem[4] = 32'h00b60633;  // add   x12, x12, x11    ; x12 = 50+100=150 (load-use hazard, stall needed)
                    mem[5] = 32'h00c02223;  // sw    x12, 4(x0)       ; mem[4] = 150
                    mem[6] = 32'h00402683;  // lw    x13, 4(x0)       ; x13 = 150 (load from mem[4])
                    mem[7] = 32'h01900513;  // addi  x10, x0, 25      ; x10 = 25
                    mem[8] = 32'h00d506b3;  // add   x13, x10, x13    ; x13 = 25+150=175 (load-use hazard, stall needed)
                    mem[9] = 32'h00d02423;  // sw    x13, 8(x0)       ; mem[8] = 175
                    mem[10] = 32'h0000006f; // jal   x0, 0            ; halt
                    $display("Test 4: Load-Use Hazard - Stall Test Loaded");
                    $display("Expected: mem[0]=100, mem[4]=150, mem[8]=175");
                    $display("Pipeline should insert stalls after lw instructions");
                end
                
                // ========================================
                // Test 5: Branch Hazard - Flush Test
                // Tests branch taken/not-taken and pipeline flush
                // Expected Results:
                //   x10 = 10, x11 = 20, x12 = 30 (branch taken)
                //   x13 = 0 (not executed), x14 = 50
                //   mem[0] = 10, mem[4] = 20, mem[8] = 30, mem[12] = 50
                // ========================================
                5: begin
                    mem[0] = 32'h00a00513;  // addi  x10, x0, 10      ; x10 = 10
                    mem[1] = 32'h01400593;  // addi  x11, x0, 20      ; x11 = 20
                    mem[2] = 32'h00b54463;  // blt   x10, x11, 8      ; 10 < 20, taken -> mem[4]
                    mem[3] = 32'h06400693;  // addi  x13, x0, 100     ; SHOULD BE FLUSHED
                    mem[4] = 32'h01e00613;  // addi  x12, x0, 30      ; x12 = 30 (executed)
                    mem[5] = 32'h00a02023;  // sw    x10, 0(x0)       ; mem[0] = 10
                    mem[6] = 32'h00b02223;  // sw    x11, 4(x0)       ; mem[4] = 20
                    mem[7] = 32'h00c02423;  // sw    x12, 8(x0)       ; mem[8] = 30
                    mem[8] = 32'h00b50663;  // beq   x10, x11, 12     ; 10 == 20? no, not taken
                    mem[9] = 32'h03200713;  // addi  x14, x0, 50      ; x14 = 50 (executed)
                    mem[10] = 32'h00e02623; // sw    x14, 12(x0)      ; mem[12] = 50
                    mem[11] = 32'h00d02823; // sw    x13, 16(x0)      ; mem[16] = 0 (x13 was never set)
                    mem[12] = 32'h0000006f; // jal   x0, 0            ; halt
                    $display("Test 5: Branch Hazard - Flush Test Loaded");
                    $display("Expected: mem[0]=10, mem[4]=20, mem[8]=30, mem[12]=50, mem[16]=0");
                    $display("Instructions after taken branch should be flushed");
                end
                
                // ========================================
                // Test 6: Jump Hazard - JAL/JALR Flush Test
                // Tests JAL and JALR with pipeline flush
                // Expected Results:
                //   x1 = 4 (return address from first jal)
                //   x10 = 100, x11 = 200
                //   mem[0] = 100, mem[4] = 200, mem[8] = 4
                // ========================================
                6: begin
                    mem[0] = 32'h00c000ef;  // jal   x1, 12           ; jump to mem[3], x1 = 4
                    mem[1] = 32'h00100513;  // addi  x10, x0, 1       ; SHOULD BE FLUSHED
                    mem[2] = 32'h00200513;  // addi  x10, x0, 2       ; SHOULD BE FLUSHED
                    mem[3] = 32'h06400513;  // addi  x10, x0, 100     ; x10 = 100 (executed)
                    mem[4] = 32'h00a02023;  // sw    x10, 0(x0)       ; mem[0] = 100
                    mem[5] = 32'h00800593;  // addi  x11, x0, 8       ; x11 = 8
                    mem[6] = 32'h02858593;  // addi  x11, x11, 40     ; x11 = 48
                    mem[7] = 32'h000580e7;  // jalr  x1, x11, 0       ; jump to address in x11 (48 = mem[12])
                    mem[8] = 32'h00300593;  // addi  x11, x0, 3       ; SHOULD BE FLUSHED
                    mem[9] = 32'h00400593;  // addi  x11, x0, 4       ; SHOULD BE FLUSHED
                    mem[10] = 32'h00500593; // addi  x11, x0, 5       ; SHOULD BE FLUSHED
                    mem[11] = 32'h00600593; // addi  x11, x0, 6       ; SHOULD BE FLUSHED
                    mem[12] = 32'h0c800593; // addi  x11, x0, 200     ; x11 = 200 (executed)
                    mem[13] = 32'h00b02223; // sw    x11, 4(x0)       ; mem[4] = 200
                    mem[14] = 32'h00102423; // sw    x1, 8(x0)        ; mem[8] = 4 (return address)
                    mem[15] = 32'h0000006f; // jal   x0, 0            ; halt
                    $display("Test 6: Jump Hazard - JAL/JALR Flush Test Loaded");
                    $display("Expected: mem[0]=100, mem[4]=200, mem[8]=4");
                    $display("Instructions after jump should be flushed");
                end
                
                // ========================================
                // Test 7: Combined Test - All Hazards
                // Tests combination of data, load-use, and control hazards
                // Expected Results:
                //   mem[0] = 30, mem[4] = 60, mem[8] = 90
                // ========================================
                7: begin
                    mem[0] = 32'h00a00513;  // addi  x10, x0, 10      ; x10 = 10
                    mem[1] = 32'h01400593;  // addi  x11, x0, 20      ; x11 = 20
                    mem[2] = 32'h00b50633;  // add   x12, x10, x11    ; x12 = 30 (data hazard)
                    mem[3] = 32'h00c02023;  // sw    x12, 0(x0)       ; mem[0] = 30 (data hazard)
                    mem[4] = 32'h00002683;  // lw    x13, 0(x0)       ; x13 = 30 (load)
                    mem[5] = 32'h00d606b3;  // add   x13, x12, x13    ; x13 = 30+30=60 (load-use hazard)
                    mem[6] = 32'h00d02223;  // sw    x13, 4(x0)       ; mem[4] = 60
                    mem[7] = 32'h00c6c463;  // blt   x13, x12, 8      ; 60 < 30? no, not taken
                    mem[8] = 32'h00d60733;  // add   x14, x12, x13    ; x14 = 30+60=90 (executed)
                    mem[9] = 32'h00e02423;  // sw    x14, 8(x0)       ; mem[8] = 90
                    mem[10] = 32'h0000006f; // jal   x0, 0            ; halt
                    $display("Test 7: Combined Test - All Hazards Loaded");
                    $display("Expected: mem[0]=30, mem[4]=60, mem[8]=90");
                end
                
                // ========================================
                // Test 8: Complex Program - Fibonacci Sequence
                // Computes first 5 Fibonacci numbers
                // Expected Results:
                //   mem[0]=1, mem[4]=1, mem[8]=2, mem[12]=3, mem[16]=5
                // ========================================
                8: begin
                    mem[0] = 32'h00100513;  // addi  x10, x0, 1       ; x10 = 1 (fib[0])
                    mem[1] = 32'h00100593;  // addi  x11, x0, 1       ; x11 = 1 (fib[1])
                    mem[2] = 32'h00a02023;  // sw    x10, 0(x0)       ; mem[0] = 1
                    mem[3] = 32'h00b02223;  // sw    x11, 4(x0)       ; mem[4] = 1
                    mem[4] = 32'h00b50633;  // add   x12, x10, x11    ; x12 = 1+1 = 2 (fib[2])
                    mem[5] = 32'h00c02423;  // sw    x12, 8(x0)       ; mem[8] = 2
                    mem[6] = 32'h00c586b3;  // add   x13, x11, x12    ; x13 = 1+2 = 3 (fib[3])
                    mem[7] = 32'h00d02623;  // sw    x13, 12(x0)      ; mem[12] = 3
                    mem[8] = 32'h00d60733;  // add   x14, x12, x13    ; x14 = 2+3 = 5 (fib[4])
                    mem[9] = 32'h00e02823;  // sw    x14, 16(x0)      ; mem[16] = 5
                    mem[10] = 32'h00e687b3; // add   x15, x13, x14    ; x15 = 3+5 = 8 (fib[5])
                    mem[11] = 32'h00f02a23; // sw    x15, 20(x0)      ; mem[20] = 8
                    mem[12] = 32'h00f70833; // add   x16, x14, x15    ; x16 = 5+8 = 13 (fib[6])
                    mem[13] = 32'h01002c23; // sw    x16, 24(x0)      ; mem[24] = 13
                    mem[14] = 32'h0000006f; // jal   x0, 0            ; halt
                    $display("Test 8: Complex Program - Fibonacci Sequence Loaded");
                    $display("Expected: mem[0]=1, mem[4]=1, mem[8]=2, mem[12]=3, mem[16]=5");
                    $display("         mem[20]=8, mem[24]=13");
                end
                
                default: begin
                    mem[0] = 32'h00000513;  // addi x10, x0, 0
                    mem[1] = 32'h0000006f;  // jal  x0, 0
                    $display("No test selected");
                end
            endcase
        `endif
        
        $display("========================================");
        $display("Instruction Memory initialized at time %t", $time);
        $display("Instruction HEX load completed");
        $display("RV32I Pipeline CPU Test Suite Loaded");
        $display("========================================");
    end

    // ========================================
    // 비동기식 읽기 (Asynchronous Read for Fetch)
    // PC 주소가 입력되면 즉시 명령어를 꺼내줍니다. 
    // disable 상태일 때는 파이프라인 오작동을 막기 위해 NOP(아무것도 안 함) 명령어를 내보냅니다.
    // ========================================
    always @(*) begin
        if (enable)
            instruction = mem[address];
        else
            instruction = 32'h00000013;  // NOP when disabled
    end

endmodule