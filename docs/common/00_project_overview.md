# RV32I 기반 MNIST CNN 가속기 SoC 설계 및 FPGA 구현

## 1. 프로젝트 개요

### 1.1 목표
RV32I 싱글 사이클 코어 내부에 CNN 추론 전용 커스텀 명령어(Custom Instruction)를 추가하여,
LeNet-5 기반 MNIST 손글씨 숫자 인식을 가속하는 SoC를 설계하고 FPGA에 구현한다.

### 1.2 핵심 전략: ISA 확장 (코어 내부 가속)
교수님 피드백 반영 — 외부 오프로딩 가속기 대신 **코어 내부에 가속기를 통합**하는 방식을 채택한다.

| 항목 | 외부 가속기 (오프로딩) | **코어 내부 확장 (채택)** |
|------|----------------------|------------------------|
| 데이터 전송 | DMA / AXI 트랜잭션 오버헤드 | 레지스터 파일 직접 접근 |
| 제어 오버헤드 | 동기화, 인터럽트 필요 | 싱글 사이클 내 자연스러운 흐름 |
| 설계 복잡도 | AXI 인터페이스, FIFO 등 필요 | ALU 옆에 CFU 추가로 상대적 간단 |
| 성능 | 큰 배치에 유리 | 소규모 추론(단일 이미지)에 유리 |

### 1.3 사용 코어
- **베이스**: 기존 싱글 사이클 RV32I 코어 (`Single_cycle/260511_Single_AXI_BRAM/`)
- **구조**: 1 사이클에 Fetch → Decode → Execute → Memory → WriteBack 완료
- **CPI**: 항상 1.0 (stall/flush 없음) → CNN 반복 루프에서 예측 가능한 성능
- **선택 근거**: CNN 추론 루프에서 파이프라인의 load-use stall / branch flush 패널티가 커서 싱글 사이클이 실효 성능 대비 구현 복잡도에서 유리

---

## 2. LeNet-5 네트워크 아키텍처 (양자화 버전)

### 2.1 네트워크 구조

```
Input(28×28×1) → [C1] Conv 5×5, 6ch → ReLU → [S2] MaxPool 2×2
              → [C3] Conv 5×5, 16ch → ReLU → [S4] MaxPool 2×2
              → [C5] Conv 5×5, 120ch (=FC)  → ReLU
              → [F6] FC 120→84            → ReLU
              → [OUT] FC 84→10           → argmax
```

### 2.2 각 레이어별 연산량 분석

| 레이어 | 입력 크기 | 커널 | 출력 크기 | MAC 연산 수 | 파라미터 수 |
|--------|-----------|------|-----------|-------------|-------------|
| C1 | 28×28×1 | 5×5×1×6 | 24×24×6 | 86,400 | 156 |
| S2 | 24×24×6 | 2×2 pool | 12×12×6 | - | 0 |
| C3 | 12×12×6 | 5×5×6×16 | 8×8×16 | 153,600 | 2,416 |
| S4 | 8×8×16 | 2×2 pool | 4×4×16 | - | 0 |
| C5 | 4×4×16 | 5×5×16×120 | 1×1×120 | 48,000 | 48,120 |
| F6 | 120 | - | 84 | 10,080 | 10,164 |
| OUT | 84 | - | 10 | 840 | 850 |
| **합계** | | | | **~299K MAC** | **~61.7K** |

### 2.3 양자화 전략: INT8 정수 양자화 (Integer Quantization)

| 항목 | 사양 |
|------|------|
| Weight | INT8 (signed, 8-bit) |
| Activation | INT8 (unsigned, 8-bit) |
| MAC 중간결과 | INT32 (누적) |
| Bias | INT32 |
| 출력 Rescale | shift + round → INT8 |

- **PyTorch에서 QAT(Quantization-Aware Training) 수행** → INT8 가중치/스케일 팩터 추출
- 총 파라미터 메모리: ~62KB (INT8) → BRAM에 충분히 수용 가능

---

## 3. 시스템 아키텍처

### 3.1 전체 블록 다이어그램

```
┌─────────────────────────────────────────────────────┐
│                   Zynq PS (ARM)                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐          │
│  │ UART     │  │ Host     │  │ Memory   │          │
│  │ Terminal │  │ Control  │  │ Loader   │          │
│  └──────────┘  └──────────┘  └──────────┘          │
│        ↕ AXI Interconnect                           │
├─────────────────────────────────────────────────────┤
│                   FPGA PL                           │
│                                                     │
│  ┌─────────────────────────────────────────┐        │
│  │    RV32I Single-Cycle Core (확장)       │        │
│  │                                         │        │
│  │  PC → [Inst Mem] → [Decoder]            │        │
│  │          ↓             ↓                │        │
│  │     instruction    control signals      │        │
│  │          ↓             ↓                │        │
│  │       [Reg File] → ┌─────────────┐      │        │
│  │         rs1,rs2     │  ALU        │      │        │
│  │                     ├─────────────┤      │        │
│  │                     │  CNN-CFU    │      │        │
│  │                     │  ·MAC4(×4)  │      │        │
│  │                     │  ·ReLU      │      │        │
│  │                     │  ·MaxPool   │      │        │
│  │                     │  ·Rescale   │      │        │
│  │                     └──────┬──────┘      │        │
│  │                  MUX(is_custom)           │        │
│  │                        ↓                 │        │
│  │              [Data Mem] ↔ result          │        │
│  │                        ↓                 │        │
│  │                   [WB → Reg File]        │        │
│  └─────────────────────────────────────────┘        │
│        ↕                    ↕                       │
│  ┌──────────┐        ┌──────────┐                   │
│  │ Inst     │        │ Data     │                   │
│  │ BRAM     │        │ BRAM     │                   │
│  │ (≥64KB)  │        │ (≥128KB) │                   │
│  └──────────┘        └──────────┘                   │
└─────────────────────────────────────────────────────┘
```

### 3.2 메모리 맵

| 영역 | 주소 범위 | 크기 | 용도 |
|------|-----------|------|------|
| Code | `0x0000_0000 ~ 0x0000_FFFF` | 64KB | 프로그램 코드 (추론 루틴) |
| Stack | `0x0001_0000 ~ 0x0001_3FFF` | 16KB | 스택 |
| Weight | `0x0002_0000 ~ 0x0002_FFFF` | 64KB | CNN 가중치 (INT8) |
| Activation | `0x0003_0000 ~ 0x0003_FFFF` | 64KB | 중간 활성화 값 버퍼 |
| Input | `0x0004_0000 ~ 0x0004_03FF` | 1KB | 입력 이미지 (28×28) |
| Result | `0x0004_0400 ~ 0x0004_04FF` | 256B | 추론 결과 |

---

## 4. 핵심 설계: 커스텀 명령어 (CNN-ISA Extension)

### 4.1 Opcode 할당

RISC-V `custom-0` 영역 사용: **opcode = `7'b0001011`** (0x0B)

### 4.2 커스텀 명령어 세트

#### 명령어 1: `MAC4` — 4-way 8-bit MAC (Multiply-Accumulate)
```
R-type: funct7[6:0] | rs2[4:0] | rs1[4:0] | funct3[2:0] | rd[4:0] | opcode[6:0]
        0000000       rs2        rs1        000            rd        0001011
```
- **동작**: `rd = rd + dot4(rs1_bytes, rs2_bytes)`
  - `rs1`의 4바이트 × `rs2`의 4바이트 → 4개의 8-bit 곱 → 32-bit 누적합
  - `rs1[7:0]×rs2[7:0] + rs1[15:8]×rs2[15:8] + rs1[23:16]×rs2[23:16] + rs1[31:24]×rs2[31:24]`
- **용도**: Conv/FC 레이어의 핵심 연산
- **한 사이클에 4 MAC → 기존 대비 ~12× 속도향상** (LW+MUL+ADD×4 → 1 instr)

#### 명령어 2: `RELU` — ReLU 활성화 함수
```
R-type: funct7[6:0] | rs2[4:0] | rs1[4:0] | funct3[2:0] | rd[4:0] | opcode[6:0]
        0000001       00000      rs1        000            rd        0001011
```
- **동작**: `rd = max(rs1, 0)` (부호 비트 기반)
- **용도**: 각 레이어 출력에 적용
- 기존: `slt + and + ...` (3~4 instr) → **1 instr**

#### 명령어 3: `MAXPOOL2` — 4개 값 중 최대값
```
R-type: funct7[6:0] | rs2[4:0] | rs1[4:0] | funct3[2:0] | rd[4:0] | opcode[6:0]
        0000010       rs2        rs1        000            rd        0001011
```
- **동작**: `rd = max(rs1[7:0], rs1[15:8], rs2[7:0], rs2[15:8])`
  - 4개의 INT8 값을 패킹하여 2×2 풀링 수행
- **용도**: MaxPool 레이어
- 기존: 비교+분기 반복 (8~12 instr) → **1 instr**

#### 명령어 4: `CLRACC` — 누적기 초기화
```
R-type: funct7[6:0] | rs2[4:0] | rs1[4:0] | funct3[2:0] | rd[4:0] | opcode[6:0]
        0000011       00000      00000      000            rd        0001011
```
- **동작**: `rd = 0` (MAC4 연산 전 누적기 초기화)
- **용도**: 새로운 출력 채널 연산 시작 시

#### 명령어 5: `RESCALE` — 양자화 스케일 변환
```
R-type: funct7[6:0] | rs2[4:0] | rs1[4:0] | funct3[2:0] | rd[4:0] | opcode[6:0]
        0000100       rs2        rs1        000            rd        0001011
```
- **동작**: `rd = clamp((rs1 * scale + round) >> rs2, 0, 255)`
  - INT32 누적 결과를 INT8로 재양자화
  - `rs2` = shift amount (scale factor를 shift로 근사)
- **용도**: 각 Conv/FC 레이어 출력 양자화

### 4.3 명령어 인코딩 요약표

| 명령어 | funct7 | rs2 | rs1 | funct3 | rd | opcode | Cycles |
|--------|--------|-----|-----|--------|-----|--------|--------|
| `MAC4` | `0000000` | src2 | src1 | `000` | dst | `0001011` | 1 |
| `RELU` | `0000001` | `00000` | src1 | `000` | dst | `0001011` | 1 |
| `MAXPOOL2` | `0000010` | src2 | src1 | `000` | dst | `0001011` | 1 |
| `CLRACC` | `0000011` | `00000` | `00000` | `000` | dst | `0001011` | 1 |
| `RESCALE` | `0000100` | shift | src1 | `000` | dst | `0001011` | 1 |

---

## 5. RTL 수정 범위

### 5.1 싱글 사이클 코어 수정 (`rv32i_cpu.v`)

베이스: `Single_cycle/260511_Single_AXI_BRAM/rtl/rv32i_cpu.v`

#### (a) Decoder 수정
```
maindec: custom-0 opcode (0001011) 추가
  → RegWrite=1, ALUSrc=0, MemtoReg=0, MemWrite=0, branch=0
  → 새로운 제어신호: is_custom = 1

aludec: custom-0일 때 funct7 기반으로 CFU 연산 선택
  → cfu_op[2:0] 신호 생성
```

#### (b) CFU (Custom Function Unit) 모듈 추가
```verilog
module cnn_cfu (
    input  [31:0] rs1_data,    // 소스 레지스터 1
    input  [31:0] rs2_data,    // 소스 레지스터 2
    input  [2:0]  cfu_op,      // 연산 선택
    output [31:0] cfu_result   // 결과
);
```

#### (c) Datapath 수정
- ALU 결과와 CFU 결과를 MUX로 선택 (싱글 사이클: 조합 로직으로 간단)
- `is_custom` 신호에 따라 `rd_data` = ALU result or CFU result
- 파이프라인 레지스터 전파 불필요 → 수정 범위 최소

### 5.2 신규 모듈

| 모듈 | 파일 | 설명 |
|------|------|------|
| `cnn_cfu.v` | 신규 | CNN Custom Function Unit (전체 CFU 통합) |

> CFU 내부에 MAC4, ReLU, MaxPool2, Rescale 로직을 모두 포함.
> 별도 파일로 분리할 필요 없을 정도로 간단 (~50줄).

### 5.3 기존 모듈 수정

| 모듈 | 파일 | 수정 내용 |
|------|------|----------|
| `maindec` | `rv32i_cpu.v` | custom-0 opcode 디코딩 추가, `is_custom` 출력 |
| `aludec` | `rv32i_cpu.v` | `cfu_op[2:0]` 출력 추가 |
| `datapath` | `rv32i_cpu.v` | CFU 인스턴스 추가, `rd_data` MUX 확장 |
| `RV32I_System` | `RV32I_System.v` | 메모리 크기 확장 |

---

## 6. 소프트웨어 스택

### 6.1 오프라인 (호스트 PC)
1. **PyTorch**: LeNet-5 학습 + INT8 QAT
2. **가중치 추출**: INT8 가중치/바이어스 → C 배열 또는 `.hex` 파일로 변환
3. **C 코드 작성**: 추론 루틴 (커스텀 명령어 사용)
4. **크로스 컴파일**: RISC-V 툴체인 (`riscv32-unknown-elf-gcc`)으로 컴파일
5. **HEX 변환**: `.elf` → `imem.hex`, `dmem.hex`

### 6.2 온라인 (SoC 위에서 실행)
```c
// 추론 루틴 의사코드
void lenet5_inference(uint8_t* input_image) {
    // C1: Conv 5x5, 6 filters
    for (int oc = 0; oc < 6; oc++) {
        CLRACC(acc);  // 커스텀: 누적기 초기화
        for (int ky = 0; ky < 5; ky++)
            for (int kx_packed = 0; kx_packed < 5; kx_packed += 4) {
                uint32_t input_packed = pack_4bytes(...);
                uint32_t weight_packed = pack_4bytes(...);
                acc = MAC4(acc, input_packed, weight_packed);  // 커스텀: 4-MAC
            }
        acc = RESCALE(acc, shift);  // 커스텀: INT32→INT8
        result = RELU(acc);         // 커스텀: ReLU
    }
    
    // S2: MaxPool 2x2
    for (...) {
        result = MAXPOOL2(packed_a, packed_b);  // 커스텀: 4값 max
    }
    
    // ... C3, S4, C5, F6, Output 반복 ...
}
```

### 6.3 어셈블리에서의 커스텀 명령어 사용
```asm
# .insn 의사지시어를 사용
# MAC4: rd = rd + dot4(rs1, rs2)
.insn r 0x0B, 0, 0, a0, a1, a2    # MAC4  a0, a1, a2

# RELU: rd = max(rs1, 0)
.insn r 0x0B, 0, 1, a0, a1, x0    # RELU  a0, a1

# MAXPOOL2: rd = max4(rs1, rs2)
.insn r 0x0B, 0, 2, a0, a1, a2    # MAXPOOL2  a0, a1, a2
```

---

## 7. 검증 계획

### 7.1 단계별 검증

| 단계 | 내용 | 도구 |
|------|------|------|
| 1 | 개별 CFU 모듈 기능 검증 | Vivado Simulator |
| 2 | 커스텀 명령어 싱글 사이클 코어 통합 검증 | Testbench (기존 TB 확장) |
| 3 | LeNet-5 추론 프로그램 시뮬레이션 | Vivado + HEX 로딩 |
| 4 | FPGA 실물 보드 검증 | Zynq Board + Vitis |

### 7.2 성능 비교 기준
- **Baseline**: 커스텀 명령어 없는 순수 RV32I 소프트웨어 추론
- **Accelerated**: 커스텀 명령어 사용 추론
- **측정 지표**: 총 사이클 수, CPI, 추론 시간(ms)

### 7.3 정확도 검증
- PyTorch 기준 결과 vs FPGA 결과 비교 (MNIST 테스트셋 일부)
- 양자화로 인한 정확도 손실 < 1% 목표

---

## 8. 개발 일정 (예시)

| 주차 | 마일스톤 |
|------|----------|
| 1주차 | PyTorch LeNet-5 학습 + INT8 양자화 |
| 2주차 | 커스텀 명령어 ISA 확정 + CFU RTL 설계 |
| 3주차 | 싱글 사이클 코어 통합 + 단위 테스트 |
| 4주차 | C 추론 코드 작성 + 시뮬레이션 검증 |
| 5주차 | FPGA 합성 + 보드 검증 |
| 6주차 | 성능 측정 + 보고서 작성 |

---

## 9. 예상 리소스 사용량 (Zynq-7020 기준)

| 리소스 | 기존 코어 | 확장 후 (예상) | 가용량 |
|--------|-----------|---------------|--------|
| LUT | ~3,000 | ~5,000 | 53,200 |
| FF | ~1,500 | ~2,500 | 106,400 |
| BRAM (36Kb) | 2 | 10~15 | 140 |
| DSP48 | 0 | 4~8 | 220 |

> MAC4에서 DSP48 블록 사용 시 타이밍 성능과 면적 효율 향상

---

## 10. 디렉토리 구조 (예정)

```
2026-1_FPGA_TermProject/
├── docs/                          # 문서
│   ├── 00_project_overview.md     # 이 문서
│   ├── 01_lenet5_architecture.md  # LeNet-5 상세 분석
│   ├── 02_custom_isa_spec.md      # ISA 확장 명세
│   ├── 03_rtl_design.md           # RTL 설계 문서
│   └── 04_verification_plan.md    # 검증 계획
├── model/                         # PyTorch 모델 & 양자화
│   ├── train_lenet5.py
│   ├── quantize.py
│   └── export_weights.py
├── sw/                            # 소프트웨어 (C/ASM)
│   ├── src/
│   │   ├── main.c
│   │   ├── lenet5_inference.c
│   │   └── weights.h
│   ├── Makefile
│   └── linker.ld
├── RV32I_FPGA/                    # 기존 코어 (레퍼런스)
│   ├── Single_cycle/              # ← 베이스 코어
│   └── Pipeline/                  # (참고용)
├── src/                           # 프로젝트 RTL
│   └── rtl/
│       ├── rv32i_cpu.v            # 수정된 싱글 사이클 코어
│       ├── basic_modules.v
│       ├── cnn_cfu.v              # CNN Custom Function Unit
│       └── RV32I_System.v
└── tb/                            # 테스트벤치
    ├── cfu_tb.v
    ├── single_cycle_cnn_tb.v
    ├── run.sh
    └── lenet5_e2e_tb.v
```
