# RV32I CNN 커스텀 명령어 ISA 명세서

## 1. 개요

### 1.1 설계 원칙
- RISC-V **custom-0** opcode 영역(`7'b0001011`, 0x0B)을 사용하여 표준 ISA와 충돌 없이 확장
- 모든 커스텀 명령어는 **R-type** 포맷을 따름 (2개 소스 레지스터, 1개 목적 레지스터)
- **단일 사이클** 실행 (싱글 사이클 코어 내에서 조합 로직으로 완료)
- 싱글 사이클 코어의 `rd_data` MUX에 자연스럽게 통합 (해저드/포워딩 고려 불필요)

### 1.2 R-type 인코딩 포맷
```
 31      25 24   20 19   15 14  12 11    7 6     0
┌─────────┬───────┬───────┬──────┬───────┬───────┐
│ funct7  │  rs2  │  rs1  │funct3│  rd   │opcode │
│ [6:0]   │ [4:0] │ [4:0] │[2:0] │ [4:0] │[6:0]  │
└─────────┴───────┴───────┴──────┴───────┴───────┘
  7 bits    5 bits  5 bits  3bits  5 bits  7 bits

opcode = 7'b0001011 (custom-0)
```

---

## 2. 명령어 정의

### 2.1 MAC4 — 4-way INT8 Multiply-Accumulate

**목적**: 컨볼루션/FC 레이어의 핵심 MAC 연산을 4배 병렬화

| 필드 | 값 | 설명 |
|------|-----|------|
| funct7 | `7'b0000000` | MAC4 식별 |
| funct3 | `3'b000` | - |
| rs1 | 소스1 | 4개의 INT8 입력값 (packed) |
| rs2 | 소스2 | 4개의 INT8 가중치 (packed) |
| rd | 목적지 | 누적 결과 (INT32) |

**의미론 (Semantics)**:
```
rd ← rd_old + (rs1[7:0]   × rs2[7:0])     // signed × signed
            + (rs1[15:8]  × rs2[15:8])
            + (rs1[23:16] × rs2[23:16])
            + (rs1[31:24] × rs2[31:24])
```

> **주의**: `rd`의 기존 값에 누적(accumulate)하므로, MAC4 전에 반드시 `CLRACC`로 초기화 필요.
> 싱글 사이클에서는 레지스터 파일 읽기와 쓰기가 같은 사이클에 발생하므로 누적 방식은 주의 필요.

**대안 설계** (누적 없이, 채택):
```
rd ← (rs1[7:0]×rs2[7:0]) + (rs1[15:8]×rs2[15:8]) + (rs1[23:16]×rs2[23:16]) + (rs1[31:24]×rs2[31:24])
```
이 경우 누적은 일반 `ADD` 명령어로 수행: `ADD rd, rd, temp`

> **설계 결정**: 비누적 방식 채택. 싱글 사이클에서 구현이 더 단순하고 안전함.

**하드웨어**:
```
             ┌──────────┐
rs1[7:0]  ──→│ 8×8 MUL  │──→ ┐
rs2[7:0]  ──→│  (INT8)  │    │
             └──────────┘    │   ┌────────┐
             ┌──────────┐    ├──→│        │
rs1[15:8] ──→│ 8×8 MUL  │──→ ┤  │ 4-input│──→ result[31:0]
rs2[15:8] ──→│  (INT8)  │    │  │  Adder │
             └──────────┘    │  │        │
             ┌──────────┐    │  └────────┘
rs1[23:16]──→│ 8×8 MUL  │──→ ┤
rs2[23:16]──→│  (INT8)  │    │
             └──────────┘    │
             ┌──────────┐    │
rs1[31:24]──→│ 8×8 MUL  │──→ ┘
rs2[31:24]──→│  (INT8)  │
             └──────────┘
```

**바이너리 인코딩 예시** (MAC4 x10, x11, x12):
```
0000000 01100 01011 000 01010 0001011
funct7  rs2   rs1  f3   rd    opcode
= 0x00C5850B
```

---

### 2.2 RELU — ReLU Activation

**목적**: `max(x, 0)` 연산을 단일 명령어로 수행

| 필드 | 값 | 설명 |
|------|-----|------|
| funct7 | `7'b0000001` | RELU 식별 |
| funct3 | `3'b000` | - |
| rs1 | 소스 | 입력값 (INT32, signed) |
| rs2 | 미사용 | `5'b00000` (x0) |
| rd | 목적지 | 결과 |

**의미론**:
```
rd ← (rs1[31] == 1'b1) ? 32'h0000_0000 : rs1
     // 음수(MSB=1)이면 0, 양수면 그대로
```

**하드웨어**:
```verilog
assign relu_result = rs1_data[31] ? 32'b0 : rs1_data;
```

---

### 2.3 MAXPOOL2 — 2×2 Max Pooling (4개 INT8 비교)

**목적**: 4개의 INT8 값 중 최대값을 선택

| 필드 | 값 | 설명 |
|------|-----|------|
| funct7 | `7'b0000010` | MAXPOOL2 식별 |
| funct3 | `3'b000` | - |
| rs1 | 소스1 | 상단 2개 값: `{val[0,1], val[0,0]}` |
| rs2 | 소스2 | 하단 2개 값: `{val[1,1], val[1,0]}` |
| rd | 목적지 | 최대값 (0-extended to 32-bit) |

**의미론**:
```
a = rs1[7:0]    // unsigned INT8
b = rs1[15:8]   // unsigned INT8
c = rs2[7:0]    // unsigned INT8
d = rs2[15:8]   // unsigned INT8
rd = zero_ext(max(a, b, c, d))
```

**하드웨어**:
```
rs1[7:0]  ──→┐              ┐
             ├─ max(a,b) ──→├─ max(ab,cd) ──→ result
rs1[15:8] ──→┘              │
rs2[7:0]  ──→┐              │
             ├─ max(c,d) ──→┘
rs2[15:8] ──→┘
```

> **주의**: 활성화 값은 ReLU 이후이므로 unsigned (≥0)로 처리

---

### 2.4 CLRACC — Accumulator Clear

**목적**: 레지스터를 0으로 초기화 (새 MAC 연산 시작 시)

| 필드 | 값 | 설명 |
|------|-----|------|
| funct7 | `7'b0000011` | CLRACC 식별 |
| funct3 | `3'b000` | - |
| rs1 | 미사용 | `5'b00000` |
| rs2 | 미사용 | `5'b00000` |
| rd | 목적지 | 초기화할 레지스터 |

**의미론**:
```
rd ← 32'h0000_0000
```

> 사실 `addi rd, x0, 0`과 동일하지만, 명시적 의미 부여 및 프로파일링 용도

---

### 2.5 RESCALE — Quantization Rescale

**목적**: INT32 누적값을 INT8 범위로 재양자화

| 필드 | 값 | 설명 |
|------|-----|------|
| funct7 | `7'b0000100` | RESCALE 식별 |
| funct3 | `3'b000` | - |
| rs1 | 소스 | INT32 누적값 |
| rs2 | shift량 | shift amount (하위 5비트 사용) |
| rd | 목적지 | 결과 (clamped INT8) |

**의미론**:
```
temp = (rs1 + (1 << (rs2-1))) >> rs2   // round half up
rd = clamp(temp, 0, 255)               // unsigned 8-bit saturation
```

**하드웨어**:
```verilog
wire [31:0] rounded = rs1_data + (1 << (rs2_data[4:0] - 1));
wire [31:0] shifted = rounded >> rs2_data[4:0];
assign rescale_result = (shifted[31])    ? 32'd0 :      // 음수 → 0
                         (shifted > 255) ? 32'd255 :     // 오버플로우 → 255
                                           shifted;      // 정상 범위
```

---

## 3. 디코더 수정 명세

### 3.1 maindec 수정

```verilog
// 기존 opcode 정의에 추가
`define OP_CUSTOM0  7'b0001011

// maindec case문에 추가
`OP_CUSTOM0: controls <= 9'b0010_0000_0;
// auipc=0, lui=0, RegWrite=1, ALUSrc=0,
// MemtoReg=0, MemWrite=0, branch=0, jal=0, jalr=0
```

**추가 출력 신호**:
```verilog
output is_custom  // custom-0 명령어 여부
assign is_custom = (opcode == `OP_CUSTOM0);
```

### 3.2 aludec 수정

```verilog
// custom-0일 때 funct7 기반 CFU 연산 선택
`OP_CUSTOM0: begin
    case(funct7)
        7'b0000000: cfu_op <= 3'b000;  // MAC4
        7'b0000001: cfu_op <= 3'b001;  // RELU
        7'b0000010: cfu_op <= 3'b010;  // MAXPOOL2
        7'b0000011: cfu_op <= 3'b011;  // CLRACC
        7'b0000100: cfu_op <= 3'b100;  // RESCALE
        default:    cfu_op <= 3'b000;
    endcase
end
```

---

## 4. 싱글 사이클 코어 통합 상세

### 4.1 데이터패스 수정

```
기존:  rs1, rs2 → [ALU] → aluout → rd_data MUX → Reg File
확장:  rs1, rs2 → [ALU]     → aluout   ─┐
       rs1, rs2 → [CNN-CFU] → cfuout   ─┼→ MUX(is_custom) → rd_data
                                          │
                                    MemRData ─┘
```

싱글 사이클이므로:
- 모든 신호가 조합 로직으로 같은 사이클 내에 결정
- 파이프라인 레지스터 전파 불필요
- 포워딩 경로 수정 불필요
- 해저드 처리 불필요

### 4.2 커스텀 명령어 실행 흐름

```
1사이클 내:
  PC → Inst Mem → Decoder → Reg Read → CFU(or ALU) → MUX → Reg Write
                                                     └→ (Data Mem 접근 없음)
```

커스텀 명령어는 메모리 접근이 없으므로 `MemtoReg=0`, `MemWrite=0`.

---

## 5. 어셈블리 사용법

### 5.1 GCC `.insn` 의사지시어

```asm
# MAC4: rd = dot4(rs1, rs2)  (비누적 버전)
.insn r 0x0B, 0, 0, a0, a1, a2    # a0 = dot4(a1, a2)

# RELU: rd = max(rs1, 0)
.insn r 0x0B, 0, 1, a0, a1, x0    # a0 = relu(a1)

# MAXPOOL2: rd = max4_uint8(rs1, rs2)
.insn r 0x0B, 0, 2, a0, a1, a2    # a0 = maxpool2(a1, a2)

# CLRACC: rd = 0
.insn r 0x0B, 0, 3, a0, x0, x0    # a0 = 0

# RESCALE: rd = clamp(rs1 >> rs2, 0, 255)
.insn r 0x0B, 0, 4, a0, a1, a2    # a0 = rescale(a1, a2)
```

### 5.2 C 인라인 어셈블리 매크로

```c
// 커스텀 명령어를 C에서 사용하기 위한 매크로
#define MAC4(rd, rs1, rs2) \
    asm volatile (".insn r 0x0B, 0, 0, %0, %1, %2" \
                  : "=r"(rd) : "r"(rs1), "r"(rs2))

#define RELU(rd, rs1) \
    asm volatile (".insn r 0x0B, 0, 1, %0, %1, x0" \
                  : "=r"(rd) : "r"(rs1))

#define MAXPOOL2(rd, rs1, rs2) \
    asm volatile (".insn r 0x0B, 0, 2, %0, %1, %2" \
                  : "=r"(rd) : "r"(rs1), "r"(rs2))

#define CLRACC(rd) \
    asm volatile (".insn r 0x0B, 0, 3, %0, x0, x0" \
                  : "=r"(rd))

#define RESCALE(rd, rs1, rs2) \
    asm volatile (".insn r 0x0B, 0, 4, %0, %1, %2" \
                  : "=r"(rd) : "r"(rs1), "r"(rs2))
```

---

## 6. 테스트 벡터

### 6.1 MAC4 테스트

```
rs1 = 0x01020304  → bytes: 1, 2, 3, 4 (signed)
rs2 = 0x02030405  → bytes: 2, 3, 4, 5 (signed)
expected = 1×2 + 2×3 + 3×4 + 4×5 = 2 + 6 + 12 + 20 = 40 (0x28)
```

### 6.2 RELU 테스트

```
rs1 = 0x00000042 (66, 양수)  → rd = 0x00000042
rs1 = 0xFFFFFFBE (-66, 음수) → rd = 0x00000000
rs1 = 0x00000000 (0)         → rd = 0x00000000
```

### 6.3 MAXPOOL2 테스트

```
rs1 = 0x00000A05  → bytes: 5, 10 (upper bytes ignored)
rs2 = 0x0000030F  → bytes: 15, 3
expected = max(5, 10, 15, 3) = 15 (0x0F)
```

### 6.4 RESCALE 테스트

```
rs1 = 0x00000800 (2048)
rs2 = 5 (shift=5)
temp = (2048 + 16) >> 5 = 2064 >> 5 = 64
expected = 64 (0x40)

rs1 = 0xFFFFFC00 (-1024, 음수)
rs2 = 4
expected = 0 (음수 clamp)

rs1 = 0x00010000 (65536)
rs2 = 4
temp = 65536 >> 4 = 4096 > 255
expected = 255 (0xFF, saturate)
```
