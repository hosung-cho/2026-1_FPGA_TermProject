# 검증 계획서

## 1. 검증 전략 개요

### 1.1 검증 계층

```
Level 4: 시스템 레벨 (FPGA 보드)
    └── MNIST 이미지 추론 정확도 + 성능 측정
Level 3: 통합 시뮬레이션 (Vivado Sim)
    └── LeNet-5 전체 추론 프로그램 실행
Level 2: 싱글 사이클 통합 테스트 (Testbench)
    └── 커스텀 명령어 + 기존 명령어 혼합 프로그램
Level 1: 모듈 단위 테스트 (Testbench)
    └── CNN-CFU 각 연산 기능 검증
```

### 1.2 검증 환경
- **시뮬레이터**: Vivado Simulator (xsim) 또는 Icarus Verilog
- **파형 분석**: Vivado Waveform Viewer
- **FPGA 보드**: Zynq-7020 (Vivado Block Design + Vitis)

---

## 2. Level 1: 모듈 단위 테스트

### 2.1 CFU 테스트벤치 (`cfu_tb.v`)

각 커스텀 연산에 대해 독립적으로 검증:

#### (a) MAC4 테스트 케이스

| 테스트 | rs1 (hex) | rs2 (hex) | 기대 결과 | 설명 |
|--------|-----------|-----------|-----------|------|
| TC1 | `0x01020304` | `0x01020304` | 30 | 1²+2²+3²+4² |
| TC2 | `0x01010101` | `0x01010101` | 4 | all ones |
| TC3 | `0xFF000000` | `0x02000000` | -2 | 음수 곱 (-1×2) |
| TC4 | `0x7F7F7F7F` | `0x02020202` | 1016 | 최대 양수×2 |
| TC5 | `0x80808080` | `0x7F7F7F7F` | -64516 | 최소×최대 |
| TC6 | `0x00000000` | `0x12345678` | 0 | 영 입력 |

#### (b) RELU 테스트 케이스

| 테스트 | rs1 (hex) | 기대 결과 | 설명 |
|--------|-----------|-----------|------|
| TC1 | `0x00000042` | `0x00000042` | 양수 통과 |
| TC2 | `0xFFFFFFBE` | `0x00000000` | 음수 → 0 |
| TC3 | `0x00000000` | `0x00000000` | 영 |
| TC4 | `0x7FFFFFFF` | `0x7FFFFFFF` | INT32 최대 |
| TC5 | `0x80000000` | `0x00000000` | INT32 최소 |

#### (c) MAXPOOL2 테스트 케이스

| 테스트 | rs1 (hex) | rs2 (hex) | 기대 결과 | 설명 |
|--------|-----------|-----------|-----------|------|
| TC1 | `0x0000_0A05` | `0x0000_030F` | 15 | max(5,10,15,3)=15 |
| TC2 | `0x0000_FF01` | `0x0000_0102` | 255 | max 경계 |
| TC3 | `0x0000_0000` | `0x0000_0000` | 0 | 모두 0 |
| TC4 | `0x0000_FFFF` | `0x0000_FFFF` | 255 | 모두 최대 |

#### (d) RESCALE 테스트 케이스

| 테스트 | rs1 | rs2 (shift) | 기대 결과 | 설명 |
|--------|-----|-------------|-----------|------|
| TC1 | 2048 | 5 | 64 | 정상 스케일링 |
| TC2 | -1024 | 4 | 0 | 음수 clamp |
| TC3 | 65536 | 4 | 255 | 오버플로우 clamp |
| TC4 | 128 | 0 | 128 | shift 0 |
| TC5 | 255 | 0 | 255 | 경계값 |

---

## 3. Level 2: 싱글 사이클 통합 테스트

### 3.1 테스트 프로그램 시나리오

#### 시나리오 A: 커스텀 명령어 기본 동작
```asm
# 간단한 MAC4 + RELU 시퀀스
addi  x10, x0, 0x01020304     # 입력 데이터 로드 (실제로는 LW 사용)
addi  x11, x0, 0x01010101     # 가중치 로드
.insn r 0x0B, 0, 0, x12, x10, x11  # MAC4: x12 = dot4(x10, x11)
.insn r 0x0B, 0, 1, x13, x12, x0   # RELU: x13 = relu(x12)
sw    x13, 0(x0)                     # 결과 저장
```

#### 시나리오 B: 포워딩 테스트 (커스텀 → 커스텀)
```asm
.insn r 0x0B, 0, 0, x10, x11, x12  # MAC4
.insn r 0x0B, 0, 1, x10, x10, x0   # RELU(MAC4 결과) ← EX→EX forward 필요
sw    x10, 0(x0)
```

#### 시나리오 C: 포워딩 테스트 (Load → 커스텀)
```asm
lw    x10, 0(x0)                     # Load
.insn r 0x0B, 0, 0, x11, x10, x12  # MAC4(loaded data) ← load-use stall
sw    x11, 4(x0)
```

#### 시나리오 D: 커스텀 + 분기 혼합
```asm
loop:
    lw    x10, 0(x5)                    # Load input
    lw    x11, 0(x6)                    # Load weight
    .insn r 0x0B, 0, 0, x12, x10, x11  # MAC4
    add   x13, x13, x12                 # Accumulate
    addi  x5, x5, 4                     # pointer++
    addi  x6, x6, 4
    addi  x7, x7, -1                    # counter--
    bne   x7, x0, loop                  # loop
```

### 3.2 기존 테스트 회귀 검증

기존 Pipeline 테스트 (Test 1~8)가 커스텀 명령어 추가 후에도 정상 동작하는지 확인:
- Test 1: Basic Pipeline (No Hazards)
- Test 3: Forwarding Test
- Test 4: Load-Use Stall Test
- Test 5: Branch Flush Test
- Test 7: Combined Hazards
- Test 8: Fibonacci

---

## 4. Level 3: 통합 시뮬레이션

### 4.1 LeNet-5 추론 프로그램 시뮬레이션

#### 준비물
1. INT8 양자화된 가중치 → `dmem.hex`에 포함
2. 테스트 MNIST 이미지 (1장) → `dmem.hex`에 포함
3. 추론 C 코드 → 크로스 컴파일 → `imem.hex`

#### 검증 항목
- [ ] 모든 레이어의 중간 출력값이 PyTorch 기준값과 일치
- [ ] 최종 argmax 결과가 정답과 일치
- [ ] 총 사이클 수 측정
- [ ] 총 사이클 수 측정 (CPI = 1.0 확인)

#### 비교 방법
```
PyTorch (FP32) → 기준 출력
PyTorch (INT8) → 양자화 기준 출력
FPGA Sim       → 실제 출력

차이 허용 범위: 각 값 ±1 (양자화 라운딩 차이)
```

### 4.2 성능 측정 방법

성능 카운터 활용 (싱글 사이클은 CPI=1이므로 명령어 수 = 사이클 수):
```verilog
// 테스트벤치에 추가
reg [63:0] dbg_total_cycles;    // 총 사이클 수
reg [63:0] dbg_custom_count;    // 커스텀 명령어 실행 횟수
```

시뮬레이션 종료 시 (halt 감지) 카운터 값 출력:
```verilog
always @(posedge clk) begin
    if (is_halted) begin
        $display("=== Performance Report ===");
        $display("Total cycles:     %d", dbg_total_cycles);
        $display("Stall cycles:     %d", dbg_stall_count);
        $display("Flush cycles:     %d", dbg_flush_count);
        $display("Custom instr:     %d", dbg_custom_count);
        $display("CPI:              %f", real'(dbg_total_cycles) / ...);
    end
end
```

---

## 5. Level 4: FPGA 보드 검증

### 5.1 Zynq 기반 시스템 구성

```
ARM PS (Host)
  │
  ├── UART: PC 터미널과 통신
  ├── AXI: BRAM에 프로그램/데이터 로딩
  │
  └── GPIO/VIO: RV32I 리셋 제어
       │
       └── RV32I + CNN-CFU (PL)
            ├── Inst BRAM
            └── Data BRAM
```

### 5.2 검증 시나리오

1. **단일 이미지 추론**: 
   - ARM에서 1장의 MNIST 이미지 + 가중치를 BRAM에 로드
   - RV32I 리셋 해제 → 추론 실행
   - 결과 메모리에서 분류 결과 읽기

2. **다중 이미지 추론**:
   - 10장의 테스트 이미지에 대해 반복
   - 정확도: 10/10 (선별된 이미지 기준)

3. **실시간 데모**:
   - PC에서 손글씨 입력 → UART로 전송 → 추론 → 결과 UART 출력

### 5.3 성능 측정 (하드웨어)

```c
// Vitis 호스트 코드에서 사이클 카운터 읽기
#define CYCLE_COUNT_ADDR  0x0004_0400  // 결과 영역에 cycle count 저장

u32 start = Xil_In32(CYCLE_COUNT_ADDR);
// ... 추론 실행 ...
u32 end = Xil_In32(CYCLE_COUNT_ADDR);
xil_printf("Inference cycles: %u\n", end - start);
```

---

## 6. 성능 비교 프레임워크

### 6.1 비교 대상

| 구성 | 설명 |
|------|------|
| Baseline-SW | 순수 RV32I 소프트웨어 추론 (곱셈=shift-and-add) |
| Custom-ISA | 커스텀 명령어 사용 추론 |
| (Optional) Baseline-M | RV32IM (M확장 포함) 소프트웨어 추론 |

### 6.2 측정 지표

| 지표 | 단위 | 측정 방법 |
|------|------|----------|
| 총 사이클 | cycles | 시뮬레이션 카운터 |
| 추론 시간 | ms | cycles / clock_freq |
| CPI | ratio | cycles / instructions |
| Stall 비율 | % | stall_cycles / total_cycles |
| FPGA 리소스 | LUT, FF, DSP, BRAM | Vivado 합성 보고서 |
| 전력 | mW | Vivado Power Report |

### 6.3 예상 결과표

| 구성 | 사이클 | 시간@100MHz | 가속비 |
|------|--------|-------------|--------|
| Baseline-SW | ~9M | ~90ms | 1.0× |
| Custom-ISA | ~670K | ~6.7ms | ~13× |

---

## 7. 체크리스트

### 7.1 RTL 검증

- [ ] CNN-CFU 모듈 단위 테스트 PASS
- [ ] MAC4: 모든 테스트 벡터 통과
- [ ] RELU: 모든 테스트 벡터 통과
- [ ] MAXPOOL2: 모든 테스트 벡터 통과
- [ ] RESCALE: 모든 테스트 벡터 통과
- [ ] 싱글 사이클 통합: 커스텀 명령어 기본 동작
- [ ] 싱글 사이클 통합: 커스텀 + 일반 명령어 혼합 정상
- [ ] 싱글 사이클 통합: CPI=1.0 확인
- [ ] 기존 테스트 회귀: Test 1~8 PASS

### 7.2 소프트웨어 검증

- [ ] PyTorch LeNet-5 FP32 학습 완료 (acc ≥ 99%)
- [ ] INT8 양자화 완료 (acc ≥ 98%)
- [ ] 가중치 C 헤더 파일 생성
- [ ] 추론 C 코드 크로스 컴파일 성공
- [ ] 시뮬레이션에서 올바른 분류 결과

### 7.3 FPGA 검증

- [ ] Vivado 합성 성공 (타이밍 통과)
- [ ] FPGA 보드에서 단일 이미지 추론 성공
- [ ] 성능 측정 완료
- [ ] 최종 데모 준비
