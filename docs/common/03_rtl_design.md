# RTL 설계 가이드

## 1. 수정 대상 모듈 개요

기존 싱글 사이클 RV32I 코어(`Single_cycle/260511_Single_AXI_BRAM/rtl/`)를 베이스로,
CNN 가속 커스텀 명령어를 지원하도록 확장한다.

### 1.1 수정 파일 목록

| 파일 | 수정 유형 | 설명 |
|------|----------|------|
| `rv32i_cpu.v` | 수정 | 디코더 확장, 데이터패스 CFU 통합 |
| `basic_modules.v` | 수정 없음 | ALU, Regfile 그대로 사용 |
| `cnn_cfu.v` | **신규** | CNN Custom Function Unit (Top) |
| `RV32I_System.v` | 수정 | 메모리 크기 확장 |

---

## 2. CNN Custom Function Unit (cnn_cfu.v)

### 2.1 모듈 인터페이스

```verilog
module cnn_cfu (
    input  [2:0]  cfu_op,       // 연산 선택 (MAC4/RELU/MAXPOOL2/CLRACC/RESCALE)
    input  [31:0] rs1_data,     // 소스 레지스터 1
    input  [31:0] rs2_data,     // 소스 레지스터 2
    output reg [31:0] cfu_result   // 결과
);
```

### 2.2 내부 구조

```verilog
module cnn_cfu (
    input  [2:0]  cfu_op,
    input  [31:0] rs1_data,
    input  [31:0] rs2_data,
    output reg [31:0] cfu_result
);

    // ===========================
    // MAC4: 4-way INT8 dot product
    // ===========================
    wire signed [15:0] prod0, prod1, prod2, prod3;
    wire signed [31:0] mac4_result;
    
    // 각 바이트를 signed 8-bit로 추출하여 곱셈
    assign prod0 = $signed(rs1_data[7:0])   * $signed(rs2_data[7:0]);
    assign prod1 = $signed(rs1_data[15:8])  * $signed(rs2_data[15:8]);
    assign prod2 = $signed(rs1_data[23:16]) * $signed(rs2_data[23:16]);
    assign prod3 = $signed(rs1_data[31:24]) * $signed(rs2_data[31:24]);
    
    // 4개의 16-bit 곱을 32-bit로 합산
    assign mac4_result = {{16{prod0[15]}}, prod0} + {{16{prod1[15]}}, prod1} +
                         {{16{prod2[15]}}, prod2} + {{16{prod3[15]}}, prod3};
    
    // ===========================
    // RELU: max(x, 0)
    // ===========================
    wire [31:0] relu_result;
    assign relu_result = rs1_data[31] ? 32'b0 : rs1_data;
    
    // ===========================
    // MAXPOOL2: 4-input unsigned 8-bit max
    // ===========================
    wire [7:0] mp_a, mp_b, mp_c, mp_d;
    wire [7:0] mp_ab, mp_cd, mp_max;
    wire [31:0] maxpool_result;
    
    assign mp_a = rs1_data[7:0];
    assign mp_b = rs1_data[15:8];
    assign mp_c = rs2_data[7:0];
    assign mp_d = rs2_data[15:8];
    assign mp_ab = (mp_a > mp_b) ? mp_a : mp_b;
    assign mp_cd = (mp_c > mp_d) ? mp_c : mp_d;
    assign mp_max = (mp_ab > mp_cd) ? mp_ab : mp_cd;
    assign maxpool_result = {24'b0, mp_max};
    
    // ===========================
    // CLRACC: output 0
    // ===========================
    wire [31:0] clracc_result;
    assign clracc_result = 32'b0;
    
    // ===========================
    // RESCALE: (rs1 + rounding) >> shift, clamped to [0, 255]
    // ===========================
    wire [4:0]  shift_amt;
    wire [31:0] rounding;
    wire [31:0] rounded;
    wire [31:0] shifted;
    wire [31:0] rescale_result;
    
    assign shift_amt = rs2_data[4:0];
    assign rounding  = (shift_amt > 0) ? (32'b1 << (shift_amt - 1)) : 32'b0;
    assign rounded   = rs1_data + rounding;
    assign shifted   = rounded >> shift_amt;
    assign rescale_result = rounded[31]      ? 32'd0   :  // 음수(rounding 후) → 0
                            (shifted > 255)  ? 32'd255 :  // 오버플로우 → 255
                                               shifted;   // 정상
    
    // ===========================
    // Output MUX
    // ===========================
    always @(*) begin
        case (cfu_op)
            3'b000:  cfu_result = mac4_result;
            3'b001:  cfu_result = relu_result;
            3'b010:  cfu_result = maxpool_result;
            3'b011:  cfu_result = clracc_result;
            3'b100:  cfu_result = rescale_result;
            default: cfu_result = 32'b0;
        endcase
    end

endmodule
```

---

## 3. 싱글 사이클 코어 수정 (rv32i_cpu.v)

### 3.1 Opcode 정의 추가

```verilog
// 기존 opcode 정의 아래에 추가
`define OP_CUSTOM0  7'b0001011    // CNN custom instructions
```

### 3.2 maindec 수정

```verilog
module maindec(input  [6:0] opcode,
               output       auipc,
               output       lui,
               output       RegWrite,
               output       ALUSrc,
               output       MemtoReg, MemWrite,
               output       branch, 
               output       jal,
               output       jalr,
               output       is_custom);    // ★ 추가

  reg [9:0] controls;    // 9→10 bits (is_custom 추가)

  assign {auipc, lui, RegWrite, ALUSrc, 
          MemtoReg, MemWrite, branch, jal, 
          jalr, is_custom} = controls;

  always @(*)
  begin
    case(opcode)
      `OP_R:        controls <= 10'b0010_0000_00;
      `OP_I_ARITH:  controls <= 10'b0011_0000_00;
      `OP_I_LOAD:   controls <= 10'b0011_1000_00;
      `OP_I_JALR:   controls <= 10'b0011_0000_10;
      `OP_S:        controls <= 10'b0001_0100_00;
      `OP_B:        controls <= 10'b0000_0010_00;
      `OP_U_LUI:    controls <= 10'b0111_0000_00;
      `OP_U_AUIPC:  controls <= 10'b1010_0000_00;
      `OP_J_JAL:    controls <= 10'b0011_0001_00;
      `OP_CUSTOM0:  controls <= 10'b0010_0000_01;  // ★ RegWrite=1, is_custom=1
      default:      controls <= 10'b0000_0000_00;
    endcase
  end

endmodule
```

### 3.3 aludec 수정

```verilog
module aludec(input      [6:0] opcode,
              input      [6:0] funct7,
              input      [2:0] funct3,
              output reg [4:0] ALUcontrol,
              output reg [2:0] cfu_op);      // ★ 추가

  always @(*) begin
    cfu_op = 3'b000;  // 기본값
    
    case(opcode)
      // ... 기존 case 유지 ...
      
      `OP_CUSTOM0: begin
          ALUcontrol <= 5'b00000;  // ALU는 사용하지 않지만 기본값
          case(funct7)
              7'b0000000: cfu_op = 3'b000;  // MAC4
              7'b0000001: cfu_op = 3'b001;  // RELU
              7'b0000010: cfu_op = 3'b010;  // MAXPOOL2
              7'b0000011: cfu_op = 3'b011;  // CLRACC
              7'b0000100: cfu_op = 3'b100;  // RESCALE
              default:    cfu_op = 3'b000;
          endcase
      end
      
      // ... 기존 default 유지 ...
    endcase
  end
    
endmodule
```

### 3.4 datapath 수정 (싱글 사이클)

싱글 사이클이므로 파이프라인 레지스터 전파가 필요 없다. 단순한 조합 로직 추가만으로 충분.

```verilog
// === 새로운 신호 ===
wire        is_custom;       // 제어 신호 (maindec에서 출력)
wire [2:0]  cfu_op;          // CFU 연산 선택 (aludec에서 출력)
wire [31:0] cfu_result;      // CFU 결과

// === CFU 인스턴스 ===
cnn_cfu i_cnn_cfu (
    .cfu_op     (cfu_op),
    .rs1_data   (rs1_data),     // 레지스터 파일에서 직접 읽은 값
    .rs2_data   (rs2_data),
    .cfu_result (cfu_result)
);

// === rd_data 선택 MUX 수정 (기존 코드 확장) ===
// 기존:
always@(*)
begin
    if      (jal | jalr)   rd_data[31:0] = pc + 4;
    else if (MemtoReg)     rd_data[31:0] = MemRData2RF;
    else if (is_custom)    rd_data[31:0] = cfu_result;    // ★ 추가
    else                   rd_data[31:0] = aluout;
end
```

> **핵심**: 싱글 사이클에서는 `rd_data` MUX에 `is_custom` 분기 한 줄만 추가하면 된다.
> 파이프라인 레지스터 전파, 포워딩 수정, 해저드 처리 등이 일절 필요 없다.

---

## 4. 메모리 시스템 확장

### 4.1 RV32I_System.v 수정

```verilog
module RV32I_System #(
  parameter [31:0] CPU_RESET_PC = 32'h0000_0000,
  parameter IMEM_DEPTH = 16384,     // 64KB (word-addressed)
  parameter DMEM_DEPTH = 65536      // 256KB (word-addressed) ★ 확장
)(
  // ... 포트 동일 ...
);
```

### 4.2 BRAM 크기 조정

- Instruction BRAM: 64KB (기존 유지 또는 확장)
- Data BRAM: **256KB** (가중치 + 활성화 + 스택)
- Vivado Block Design에서 BRAM Controller 크기 조정 필요

---

## 5. 합성 최적화 힌트

### 5.1 MAC4 DSP48 매핑

Xilinx DSP48E1은 25×18 곱셈기를 포함. INT8×INT8는 이에 충분히 맞음.
4개의 곱셈을 병렬 수행하려면 **4개의 DSP48** 사용.

```verilog
// Vivado가 자동으로 DSP48에 매핑하도록 유도
(* use_dsp = "yes" *)
wire signed [15:0] prod0 = $signed(rs1_data[7:0]) * $signed(rs2_data[7:0]);
```

### 5.2 타이밍 고려

- MAC4의 4개 곱셈 + 3-level 덧셈 트리: 조합 로직 지연이 클 수 있음
- 100MHz 동작 기준으로 1 사이클 내 완료 가능 여부 확인 필요
- 필요 시 MAC4를 2 사이클로 분할 (곱셈 → 덧셈)

### 5.3 면적 최적화

- RELU, CLRACC는 거의 로직 소모 없음
- MAXPOOL2는 3개의 비교기만 필요
- RESCALE의 variable shift가 가장 큰 MUX 트리 생성 → barrel shifter 사용

---

## 6. 싱글 사이클의 장점: 해저드 처리 불필요

### 6.1 파이프라인 대비 수정 범위 비교

| 항목 | 싱글 사이클 (채택) | 파이프라인 |
|------|-------------------|-----------|
| 디코더 수정 | case 한 줄 추가 | 동일 |
| 데이터패스 | `rd_data` MUX 한 줄 추가 | EX 결과 MUX + 파이프라인 레지스터 전파 |
| 포워딩 | **필요 없음** | 기존 포워딩 경로 활용 필요 |
| 해저드 | **필요 없음** | load-use 검사 범위 확장 필요 |
| 테스트 | 간단 (CPI=1 고정) | 복잡 (stall/flush 케이스 다수) |

### 6.2 MAC4 누적 패턴

```asm
CLRACC  a0            # a0 = 0
MAC4    a3, a1, a2    # a3 = dot4(a1, a2)
ADD     a0, a0, a3    # a0 += mac4_result
MAC4    a3, a4, a5    # a3 = dot4(a4, a5)
ADD     a0, a0, a3    # a0 += dot4(a4, a5)
```

비누적 MAC4 + 일반 ADD 조합으로 구현.
싱글 사이클에서는 모든 명령어가 1사이클에 완료되므로 데이터 의존성 문제가 없다.
