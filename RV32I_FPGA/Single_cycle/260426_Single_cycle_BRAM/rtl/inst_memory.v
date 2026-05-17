`timescale 1 ns / 1 ns

module inst_memory #(
    parameter DEPTH = 2048,
    parameter INIT_HEX = "imem.hex"
) (
    input               clock,
    input               enable,
    input      [13:0]   address,      // 16384 words (64KB)
    output reg [31:0]   instruction
);

    // Force LUTRAM-style ROM inference for small/medium FPGA bring-up images.
    (* ram_style = "block", rom_style = "block" *) reg [31:0] mem [0:DEPTH-1];
    
    integer i;

    // Initialize instruction memory
    initial begin
        // Initialize all memory to NOP (addi x0, x0, 0)
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = 32'h00000013;  // NOP
        end
        
        // Load instructions from file
        $readmemh(INIT_HEX, mem);

        // ========================================
        // Select Test: Change TEST_SELECT to choose test
        // 1: I-Type Arithmetic & Logic
        // 2: R-Type Arithmetic & Logic  
        // 3: Shift Operations (I-Type & R-Type)
        // 4: Load & Store (I-Type Load, S-Type Store)
        // 5: Branch Instructions (B-Type)
        // 6: Jump Instructions (J-Type JAL, I-Type JALR)
        // 7: Upper Immediate (U-Type LUI, AUIPC)
        // ========================================
        
        // Built-in tests are disabled by default for external HEX-based programs.
        // To use built-in tests, define INTERNAL_TEST_SELECT and TEST_SELECT.
        `ifdef INTERNAL_TEST_SELECT
            case (`TEST_SELECT)
                // ========================================
                // Test 1: I-Type Arithmetic & Logic
                // Registers: x10-x15, Memory: 0-8
                // ========================================
                1: begin
                    mem[0] = 32'h00a00513;  // addi  x10, x0, 10      ; x10 = 10
                    mem[1] = 32'h00500593;  // addi  x11, x0, 5       ; x11 = 5
                    mem[2] = 32'hfff58613;  // addi  x12, x11, -1     ; x12 = 4
                    mem[3] = 32'h00552693;  // slti  x13, x10, 5      ; x13 = 0 (10 < 5? no)
                    mem[4] = 32'h00a53713;  // sltiu x14, x10, 10     ; x14 = 0 (10 < 10? no)
                    mem[5] = 32'h00c54793;  // xori  x15, x10, 12     ; x15 = 10^12 = 6
                    mem[6] = 32'h00556513;  // ori   x10, x10, 5      ; x10 = 10|5 = 15
                    mem[7] = 32'h00c5f593;  // andi  x11, x11, 12     ; x11 = 5&12 = 4
                    mem[8] = 32'h00a02023;  // sw    x10, 0(x0)       ; mem[0] = 15
                    mem[9] = 32'h00b02223;  // sw    x11, 4(x0)       ; mem[4] = 4
                    mem[10] = 32'h00c02423; // sw    x12, 8(x0)       ; mem[8] = 4
                    mem[11] = 32'h0000006f; // jal   x0, 0            ; halt
                    $display("Test 1: I-Type Arithmetic & Logic Loaded");
                end
                
                // ========================================
                // Test 2: R-Type Arithmetic & Logic
                // Registers: x10-x15, Memory: 0-12
                // ========================================
                2: begin
                    mem[0] = 32'h01400513;  // addi  x10, x0, 20      ; x10 = 20
                    mem[1] = 32'h00800593;  // addi  x11, x0, 8       ; x11 = 8
                    mem[2] = 32'h00b50633;  // add   x12, x10, x11    ; x12 = 20+8 = 28
                    mem[3] = 32'h40b506b3;  // sub   x13, x10, x11    ; x13 = 20-8 = 12
                    mem[4] = 32'h00b52733;  // slt   x14, x10, x11    ; x14 = 0 (20<8? no)
                    mem[5] = 32'h00b53793;  // sltu  x15, x10, x11    ; x15 = 0 (20<8? no)
                    mem[6] = 32'h00b54533;  // xor   x10, x10, x11    ; x10 = 20^8 = 28
                    mem[7] = 32'h00c5e5b3;  // or    x11, x11, x12    ; x11 = 8|28 = 28
                    mem[8] = 32'h00d67633;  // and   x12, x12, x13    ; x12 = 28&12 = 12
                    mem[9] = 32'h00a02023;  // sw    x10, 0(x0)       ; mem[0] = 28
                    mem[10] = 32'h00b02223; // sw    x11, 4(x0)       ; mem[4] = 28
                    mem[11] = 32'h00c02423; // sw    x12, 8(x0)       ; mem[8] = 12
                    mem[12] = 32'h00d02623; // sw    x13, 12(x0)      ; mem[12] = 12
                    mem[13] = 32'h0000006f; // jal   x0, 0            ; halt
                    $display("Test 2: R-Type Arithmetic & Logic Loaded");
                end
                
                // ========================================
                // Test 3: Shift Operations
                // Registers: x10-x15, Memory: 0-20
                // ========================================
                3: begin
                    mem[0] = 32'h01000513;  // addi  x10, x0, 16      ; x10 = 16
                    mem[1] = 32'h00200593;  // addi  x11, x0, 2       ; x11 = 2 (shift amount)
                    mem[2] = 32'h00300613;  // addi  x12, x0, 3       ; x12 = 3 (shift amount)
                    mem[3] = 32'h00251693;  // slli  x13, x10, 2      ; x13 = 16<<2 = 64
                    mem[4] = 32'h00255713;  // srli  x14, x10, 2      ; x14 = 16>>2 = 4
                    mem[5] = 32'h40255793;  // srai  x15, x10, 2      ; x15 = 16>>>2 = 4
                    mem[6] = 32'h00b51533;  // sll   x10, x10, x11    ; x10 = 16<<2 = 64
                    mem[7] = 32'h00c555b3;  // srl   x11, x10, x12    ; x11 = 64>>3 = 8
                    mem[8] = 32'h40c55633;  // sra   x12, x10, x12    ; x12 = 64>>>3 = 8
                    mem[9] = 32'h00a02023;  // sw    x10, 0(x0)       ; mem[0] = 64
                    mem[10] = 32'h00b02223; // sw    x11, 4(x0)       ; mem[4] = 8
                    mem[11] = 32'h00c02423; // sw    x12, 8(x0)       ; mem[8] = 8
                    mem[12] = 32'h00d02623; // sw    x13, 12(x0)      ; mem[12] = 64
                    mem[13] = 32'h00e02823; // sw    x14, 16(x0)      ; mem[16] = 4
                    mem[14] = 32'h00f02a23; // sw    x15, 20(x0)      ; mem[20] = 4
                    mem[15] = 32'h0000006f; // jal   x0, 0            ; halt
                    $display("Test 3: Shift Operations Loaded");
                end
                
                // ========================================
                // Test 4: Load & Store
                // Registers: x10-x15, Memory: 0-20
                // ========================================
                4: begin
                    mem[0] = 32'h06400513;  // addi  x10, x0, 100     ; x10 = 100
                    mem[1] = 32'h0c800593;  // addi  x11, x0, 200     ; x11 = 200
                    mem[2] = 32'h00a02023;  // sw    x10, 0(x0)       ; mem[0] = 100
                    mem[3] = 32'h00b02223;  // sw    x11, 4(x0)       ; mem[4] = 200
                    mem[4] = 32'h00a02423;  // sh    x10, 8(x0)       ; mem[8] = 100 (half)
                    mem[5] = 32'h00b02623;  // sb    x11, 12(x0)      ; mem[12] = 200 (byte)
                    mem[6] = 32'h00002603;  // lw    x12, 0(x0)       ; x12 = 100
                    mem[7] = 32'h00402683;  // lw    x13, 4(x0)       ; x13 = 200
                    mem[8] = 32'h00801703;  // lh    x14, 8(x0)       ; x14 = 100 (signed)
                    mem[9] = 32'h00805783;  // lhu   x15, 8(x0)       ; x15 = 100 (unsigned)
                    mem[10] = 32'h00c00503; // lb    x10, 12(x0)      ; x10 = -56 (signed byte)
                    mem[11] = 32'h00c04583; // lbu   x11, 12(x0)      ; x11 = 200 (unsigned byte)
                    mem[12] = 32'h00c02823; // sw    x12, 16(x0)      ; mem[16] = 100
                    mem[13] = 32'h00d02a23; // sw    x13, 20(x0)      ; mem[20] = 200
                    mem[14] = 32'h0000006f; // jal   x0, 0            ; halt
                    $display("Test 4: Load & Store Loaded");
                end
                
                // ========================================
                // Test 5: Branch Instructions
                // Registers: x10-x15, Memory: 0-12
                // ========================================
                5: begin
                    mem[0] = 32'h00a00513;  // addi  x10, x0, 10      ; x10 = 10
                    mem[1] = 32'h00a00593;  // addi  x11, x0, 10      ; x11 = 10
                    mem[2] = 32'h00500613;  // addi  x12, x0, 5       ; x12 = 5
                    mem[3] = 32'h00b50663;  // beq   x10, x11, 12     ; taken -> mem[6]
                    mem[4] = 32'h00100693;  // addi  x13, x0, 1       ; skipped
                    mem[5] = 32'h0080006f;  // jal   x0, 8            ; skipped
                    mem[6] = 32'h00200693;  // addi  x13, x0, 2       ; x13 = 2 (executed)
                    mem[7] = 32'h00c59463;  // bne   x11, x12, 8      ; taken -> mem[9]
                    mem[8] = 32'h00300713;  // addi  x14, x0, 3       ; skipped
                    mem[9] = 32'h00400713;  // addi  x14, x0, 4       ; x14 = 4 (executed)
                    mem[10] = 32'h00c54463; // blt   x10, x12, 8      ; not taken (10<5? no)
                    mem[11] = 32'h00500793; // addi  x15, x0, 5       ; x15 = 5 (executed)
                    mem[12] = 32'h00a65463; // bge   x12, x10, 8      ; not taken (5>=10? no)
                    mem[13] = 32'h00600513; // addi  x10, x0, 6       ; x10 = 6 (executed)
                    mem[14] = 32'h00d02023; // sw    x13, 0(x0)       ; mem[0] = 2
                    mem[15] = 32'h00e02223; // sw    x14, 4(x0)       ; mem[4] = 4
                    mem[16] = 32'h00f02423; // sw    x15, 8(x0)       ; mem[8] = 5
                    mem[17] = 32'h00a02623; // sw    x10, 12(x0)      ; mem[12] = 6
                    mem[18] = 32'h0000006f; // jal   x0, 0            ; halt
                    $display("Test 5: Branch Instructions Loaded");
                end
                
                // ========================================
                // Test 6: Jump Instructions (JAL, JALR)
                // Registers: x1, x10-x13, Memory: 0-12
                // ========================================
                6: begin
                    mem[0] = 32'h00c000ef;  // jal   x1, 12           ; x1=PC+4=4, jump -> mem[3]
                    mem[1] = 32'h00100513;  // addi  x10, x0, 1       ; skipped
                    mem[2] = 32'h00200513;  // addi  x10, x0, 2       ; skipped
                    mem[3] = 32'h00a00593;  // addi  x11, x0, 10      ; x11 = 10 (executed)
                    mem[4] = 32'h00b02023;  // sw    x11, 0(x0)       ; mem[0] = 10
                    mem[5] = 32'h008000ef;  // jal   x1, 8            ; x1=PC+4=24, jump -> mem[7]
                    mem[6] = 32'h00300593;  // addi  x11, x0, 3       ; skipped
                    mem[7] = 32'h01400613;  // addi  x12, x0, 20      ; x12 = 20 (executed)
                    mem[8] = 32'h00c02223;  // sw    x12, 4(x0)       ; mem[4] = 20
                    mem[9] = 32'h03800093;  // addi  x1, x0, 56       ; x1 = 56 (address of mem[14])
                    mem[10] = 32'hffc08067; // jalr  x0, x1, -4       ; jump to 56-4=52 (mem[13])
                    mem[11] = 32'h00400613; // addi  x12, x0, 4       ; skipped
                    mem[12] = 32'h00500613; // addi  x12, x0, 5       ; skipped
                    mem[13] = 32'h01e00693; // addi  x13, x0, 30      ; x13 = 30 (executed)
                    mem[14] = 32'h00d02423; // sw    x13, 8(x0)       ; mem[8] = 30
                    mem[15] = 32'h06400713; // addi  x14, x0, 100     ; x14 = 100 (success)
                    mem[16] = 32'h00e02623; // sw    x14, 12(x0)      ; mem[12] = 100
                    mem[17] = 32'h0000006f; // jal   x0, 0            ; halt
                    $display("Test 6: Jump Instructions Loaded");
                end
                
                // ========================================
                // Test 7: Upper Immediate (LUI, AUIPC)
                // Registers: x10-x15, Memory: 0-12
                // ========================================
                7: begin
                    mem[0] = 32'h12345537;  // lui   x10, 0x12345     ; x10 = 0x12345000
                    mem[1] = 32'h67850513;  // addi  x10, x10, 0x678  ; x10 = 0x12345678
                    mem[2] = 32'h00050593;  // addi  x11, x10, 0      ; x11 = 0x12345678 (copy)
                    mem[3] = 32'h00000617;  // auipc x12, 0           ; x12 = PC (0x0C)
                    mem[4] = 32'h00001697;  // auipc x13, 1           ; x13 = PC+0x1000
                    mem[5] = 32'habcde737;  // lui   x14, 0xabcde     ; x14 = 0xabcde000
                    mem[6] = 32'hfff00793;  // addi  x15, x0, -1      ; x15 = 0xFFFFFFFF
                    mem[7] = 32'h00a02023;  // sw    x10, 0(x0)       ; mem[0] = 0x12345678
                    mem[8] = 32'h00b02223;  // sw    x11, 4(x0)       ; mem[4] = 0x12345678
                    mem[9] = 32'h00c02423;  // sw    x12, 8(x0)       ; mem[8] = PC
                    mem[10] = 32'h00d02623; // sw    x13, 12(x0)      ; mem[12] = PC+0x1000
                    mem[11] = 32'h00e02823; // sw    x14, 16(x0)      ; mem[16] = 0xabcde000
                    mem[12] = 32'h0000006f; // jal   x0, 0            ; halt
                    $display("Test 7: Upper Immediate Loaded");
                end
                
                default: begin
                    mem[0] = 32'h00000513;  // addi x10, x0, 0
                    mem[1] = 32'h0000006f;  // jal  x0, 0
                    $display("No test selected");
                end
            endcase
        `endif
        
        $display("Instruction Memory initialized at time %t", $time);
        $display("Instruction HEX load completed");
    end

    // Asynchronous read for instruction fetch
    always @(posedge clock) begin
        if (enable)
            instruction = mem[address];
        else
            instruction = 32'h00000013;  // NOP when disabled
    end

endmodule