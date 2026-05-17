`timescale 1ns/1ns

// ============================================================
// CNN Custom Function Unit (CFU)
// - 5개의 CNN 전용 연산을 조합 로직으로 수행
// - 싱글 사이클 RV32I 코어의 datapath에 통합
// ============================================================
module cnn_cfu (
    input  [2:0]  cfu_op,        // 연산 선택
    input  [31:0] rs1_data,      // 소스 레지스터 1
    input  [31:0] rs2_data,      // 소스 레지스터 2
    output reg [31:0] cfu_result // 연산 결과
);

    // CFU operation codes
    localparam CFU_MAC4     = 3'b000;
    localparam CFU_RELU     = 3'b001;
    localparam CFU_MAXPOOL2 = 3'b010;
    localparam CFU_CLRACC   = 3'b011;
    localparam CFU_RESCALE  = 3'b100;

    // ===========================
    // MAC4: 4-way INT8 dot product (non-accumulating)
    // rd = dot4(rs1_bytes, rs2_bytes)
    //    = rs1[7:0]*rs2[7:0] + rs1[15:8]*rs2[15:8]
    //    + rs1[23:16]*rs2[23:16] + rs1[31:24]*rs2[31:24]
    // ===========================
    wire signed [15:0] prod0, prod1, prod2, prod3;
    wire signed [31:0] mac4_result;
    
    assign prod0 = $signed(rs1_data[ 7: 0]) * $signed(rs2_data[ 7: 0]);
    assign prod1 = $signed(rs1_data[15: 8]) * $signed(rs2_data[15: 8]);
    assign prod2 = $signed(rs1_data[23:16]) * $signed(rs2_data[23:16]);
    assign prod3 = $signed(rs1_data[31:24]) * $signed(rs2_data[31:24]);
    
    // sign-extend each 16-bit product to 32-bit before summing
    assign mac4_result = {{16{prod0[15]}}, prod0}
                       + {{16{prod1[15]}}, prod1}
                       + {{16{prod2[15]}}, prod2}
                       + {{16{prod3[15]}}, prod3};

    // ===========================
    // RELU: max(x, 0)
    // ===========================
    wire [31:0] relu_result;
    assign relu_result = rs1_data[31] ? 32'b0 : rs1_data;

    // ===========================
    // MAXPOOL2: 4-input unsigned 8-bit max
    // rs1 = {xx, xx, b, a}, rs2 = {xx, xx, d, c}
    // result = max(a, b, c, d)  (unsigned comparison)
    // ===========================
    wire [7:0] mp_a, mp_b, mp_c, mp_d;
    wire [7:0] mp_ab, mp_cd, mp_max;
    wire [31:0] maxpool_result;
    
    assign mp_a = rs1_data[ 7:0];
    assign mp_b = rs1_data[15:8];
    assign mp_c = rs2_data[ 7:0];
    assign mp_d = rs2_data[15:8];
    assign mp_ab  = (mp_a > mp_b) ? mp_a : mp_b;
    assign mp_cd  = (mp_c > mp_d) ? mp_c : mp_d;
    assign mp_max = (mp_ab > mp_cd) ? mp_ab : mp_cd;
    assign maxpool_result = {24'b0, mp_max};

    // ===========================
    // CLRACC: output zero
    // ===========================
    wire [31:0] clracc_result;
    assign clracc_result = 32'b0;

    // ===========================
    // RESCALE: (rs1 + rounding) >> shift, clamped to [0, 255]
    // rs2[4:0] = shift amount
    // ===========================
    wire [4:0]  shift_amt;
    wire [31:0] rounding;
    wire signed [31:0] rounded;
    wire signed [31:0] shifted;
    wire [31:0] rescale_result;
    
    assign shift_amt = rs2_data[4:0];
    assign rounding  = (shift_amt != 0) ? (32'd1 << (shift_amt - 1)) : 32'd0;
    assign rounded   = $signed(rs1_data) + $signed(rounding);
    assign shifted   = rounded >>> shift_amt;  // arithmetic shift (signed wire)
    // Clamp: negative → 0, >255 → 255
    assign rescale_result = shifted[31]          ? 32'd0   :  // negative → 0
                            (shifted > 32'sd255) ? 32'd255 :  // overflow → 255
                                                   shifted;   // normal

    // ===========================
    // Output MUX
    // ===========================
    always @(*) begin
        case (cfu_op)
            CFU_MAC4:     cfu_result = mac4_result;
            CFU_RELU:     cfu_result = relu_result;
            CFU_MAXPOOL2: cfu_result = maxpool_result;
            CFU_CLRACC:   cfu_result = clracc_result;
            CFU_RESCALE:  cfu_result = rescale_result;
            default:      cfu_result = 32'b0;
        endcase
    end

endmodule
