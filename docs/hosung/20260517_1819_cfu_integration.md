# 싱글 사이클 코어 CNN-CFU 통합 완료

## 작업 일시
2026-05-17 18:19 ~ 18:27

## 작업 내용

### 1. 베이스 코어 복사 및 수정

베이스: `RV32I_FPGA/Single_cycle/260511_Single_AXI_BRAM/rtl/`
대상: `src/rtl/` (프로젝트 작업 디렉토리)

복사한 파일:
- `rv32i_cpu.v` → 수정 (커스텀 명령어 지원)
- `basic_modules.v` → 수정 없음 (regfile, alu, adder 그대로)
- `cnn_cfu.v` → 1단계에서 이미 작성 완료

### 2. rv32i_cpu.v 수정 내역

총 **7곳** 수정, 기존 코드의 기능은 100% 유지:

#### 2.1 Opcode 정의 추가 (1줄)
```verilog
`define OP_CUSTOM0  7'b0001011    // CNN custom-0
```

#### 2.2 maindec 수정 (controls 9→10비트)
```diff
- reg [8:0] controls;
+ reg [9:0] controls;
  assign {..., jalr, is_custom} = controls;
+ `OP_CUSTOM0: controls <= 10'b0010_0000_01;  // RegWrite=1, is_custom=1
```
- `is_custom` 출력 추가
- 기존 모든 opcode에 `_0` 추가 (is_custom=0)

#### 2.3 aludec 수정 (cfu_op 출력 추가)
```verilog
`OP_CUSTOM0: begin
    ALUcontrol <= 5'b00000;
    case(funct7)
        7'b0000000: cfu_op = 3'b000;  // MAC4
        7'b0000001: cfu_op = 3'b001;  // RELU
        7'b0000010: cfu_op = 3'b010;  // MAXPOOL2
        7'b0000011: cfu_op = 3'b011;  // CLRACC
        7'b0000100: cfu_op = 3'b100;  // RESCALE
    endcase
end
```

#### 2.4 datapath 수정 (CFU 인스턴스 + MUX 1줄)
```verilog
cnn_cfu i_cnn_cfu(.cfu_op(cfu_op), .rs1_data(rs1_data), .rs2_data(rs2_data), .cfu_result(cfu_result));

// rd_data MUX에 1줄 추가
else if (is_custom) rd_data = cfu_result;
```

#### 2.5 controller, top module 포트 연결
- `is_custom`, `cfu_op` 시그널을 controller → datapath로 전달

### 3. 통합 테스트벤치

**위치**: `testbench/2_cfu_integration/`

내부 메모리 시스템(`RV32I_CNN_TestSystem`)을 테스트벤치용으로 작성:
- `imem.hex`: 커스텀 명령어 포함 테스트 프로그램 (26 instructions)
- `dmem.hex`: 테스트 데이터 (12 words)

### 4. 테스트 케이스 및 결과

| # | 테스트 | 레지스터 | 기대값 | 결과 |
|---|--------|----------|--------|------|
| 1 | MAC4 기본 | x10 | 40 (0x28) | ✅ PASS |
| 2 | RELU 양수 | x11 | 40 (0x28) | ✅ PASS |
| 3 | RELU 음수 | x12 | 0 | ✅ PASS |
| 4 | MAXPOOL2 | x13 | 15 (0x0F) | ✅ PASS |
| 5 | CLRACC | x14 | 0 | ✅ PASS |
| 6 | RESCALE | x15 | 64 (0x40) | ✅ PASS |
| 7 | MAC4+ADD 누적 | x16 | 20 (0x14) | ✅ PASS |
| 8 | MAC4→RESCALE→RELU 연쇄 | x17 | 25 (0x19) | ✅ PASS |

**ALL 8 TESTS PASSED** ✅

### 5. 커스텀 명령어 인코딩 검증

실제 사용한 바이너리 인코딩 예시:

| 명령어 | 바이너리 | HEX |
|--------|----------|-----|
| `MAC4 x10, x1, x2` | `0000000_00010_00001_000_01010_0001011` | `0x0020850B` |
| `RELU x11, x10` | `0000001_00000_01010_000_01011_0001011` | `0x0205058B` |
| `MAXPOOL2 x13, x4, x5` | `0000010_00101_00100_000_01101_0001011` | `0x0452068B` |
| `CLRACC x14` | `0000011_00000_00000_000_01110_0001011` | `0x0600070B` |
| `RESCALE x15, x6, x21` | `0000100_10101_00110_000_01111_0001011` | `0x0953078B` |

### 6. 실행 방법

```bash
cd testbench/2_cfu_integration/sim
bash run.sh
```

### 7. 핵심 설계 포인트

1. **기존 코드 완전 보존**: 기존 RV32I 명령어 동작에 영향 없음
2. **최소 수정**: `rd_data` MUX에 `is_custom` 분기 1줄만 추가
3. **조합 로직만**: CFU는 순수 조합 로직 → 싱글 사이클 CPI=1 유지
4. **포워딩/해저드 불필요**: 싱글 사이클 → 데이터 의존성 문제 없음

## 다음 단계

3단계: PyTorch LeNet-5 학습 + INT8 양자화 + 가중치 HEX 추출
