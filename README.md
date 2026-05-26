# RV32I + CNN_ALU FPGA Term Project

본 프로젝트는 직접 구현한 RV32I 프로세서에 CNN 전용 연산 블록인 `CNN_ALU`를 추가하고, Zynq-7020 FPGA 보드에서 LeNet INT8 추론을 실제로 실행한 텀프로젝트입니다.

최종 목표는 단순 시뮬레이션이 아니라 다음 흐름을 실제 보드에서 end-to-end로 검증하는 것이었습니다.

```text
입력 이미지 로드
  -> RV32I firmware 실행
  -> CNN_ALU 기반 LeNet INT8 추론
  -> 예측 결과를 TFT-LCD에 표시
```

## 프로젝트 목표

- RV32I 기반 pipeline CPU에서 LeNet INT8 inference 실행
- CNN 연산을 가속하기 위한 custom instruction 및 `CNN_ALU` 설계
- HLS로 작성한 CNN_ALU를 RTL로 변환하여 RV32I datapath에 통합
- Zynq PS와 PL을 AXI로 연결하여 보드에서 실행 제어
- External BRAM 구조를 사용해 입력 데이터를 쉽게 교체
- 보드 내장 4.3인치 TFT-LCD에 추론 결과 출력
- `RV32I-only` 구조와 `RV32I + CNN_ALU` 구조를 같은 조건에서 비교

## 전체 구조

최종 보드 구조는 다음과 같습니다.

```text
Zynq PS
  -> AXI Interconnect
     -> RV32I control/status AXI-Lite
     -> AXI BRAM Controller + External dmem BRAM
     -> TFT-LCD AXI framebuffer

RV32I CPU
  -> 일반 RV32I ALU
  -> CNN_ALU custom operation path
  -> External dmem BRAM
```

PS는 입력 데이터 로드와 실행 제어를 담당하고, PL 내부의 RV32I CPU와 CNN_ALU가 실제 LeNet INT8 연산을 수행합니다. 추론 결과는 LCD framebuffer를 통해 보드의 TFT-LCD에 표시됩니다.

## CNN_ALU 개요

`CNN_ALU`는 CNN 추론에서 반복적으로 등장하는 연산을 RV32I 일반 명령어 대신 전용 명령으로 처리하기 위해 추가한 연산 블록입니다.

주요 기능은 다음과 같습니다.

- packed INT8 weight/activation load
- 4-lane INT8 MAC
- 5x5 convolution용 dot product
- FC layer용 누산 MAC
- 2x2 max pooling
- bias add
- requantization
- ReLU
- result readback

RV32I instruction의 custom opcode를 사용하고, `funct3`와 `funct7[0]` 조합으로 4-bit `cnn_op`를 생성해 CNN_ALU 내부 명령을 선택합니다.

## External BRAM 구조

초기 구조에서는 data memory가 RV32I 내부에 가까운 형태였기 때문에 입력 이미지를 바꾸기 어려웠습니다. 최종 구조에서는 data memory를 `Block Memory Generator` 기반의 외부 BRAM으로 분리했습니다.

```text
External dmem BRAM
  - 32-bit data width
  - 32768 word depth
  - total 128 KB
```

이 구조에서는 PS가 실행 전에 BRAM에 입력 dmem 이미지를 직접 로드하고, RV32I는 해당 BRAM을 data memory처럼 사용합니다. 덕분에 0부터 9까지 여러 digit 이미지를 순차적으로 테스트할 수 있습니다.

## Address Map

| Peripheral | Base Address | Range | Purpose |
| --- | ---: | ---: | --- |
| RV32I control/status | `0x43C00000` | 64 KB | 실행 제어, 상태 확인, 결과 및 cycle counter 확인 |
| External dmem BRAM | `0x43C40000` | 128 KB | 입력 이미지 및 data memory 로드 |
| TFT-LCD framebuffer | `0x43C80000` | 512 KB | LCD RGB565 framebuffer |

## 보드 검증 결과

Zynq-7020 보드에서 0부터 9까지 모든 입력 이미지를 External BRAM에 로드하고, 추론 결과가 LCD에 정상 표시되는 것을 확인했습니다.

```text
0~9 total runs: 10
0~9 total pass: 10
all pass: 1
```

## 성능 비교

비교 조건은 다음과 같이 맞췄습니다.

- 동일한 보드
- 동일한 100 MHz clock
- 동일한 External BRAM 구조
- 동일한 TFT-LCD 출력 구조
- 동일한 0~9 입력 dmem 이미지
- 차이는 `CNN_ALU_Top` 포함 여부만 존재

| Version | Average Cycles | Average Latency @100MHz | Result |
| --- | ---: | ---: | --- |
| RV32I + CNN_ALU | 약 8.63M cycles | 약 86.26 ms | 0~9 all pass |
| RV32I-only | 약 86.08M cycles | 약 860.78 ms | 0~9 all pass |

평균 기준으로 `RV32I + CNN_ALU` 구조가 `RV32I-only` 구조 대비 약 `9.98x` 빠르게 동작했습니다.

## 리소스 사용량

| Resource | RV32I + CNN_ALU | Utilization | RV32I-only | Utilization | Difference |
| --- | ---: | ---: | ---: | ---: | ---: |
| LUT | 4,234 | 7.96% | 3,545 | 6.66% | +689 |
| Register | 3,782 | 3.55% | 2,516 | 2.36% | +1,266 |
| BRAM | 96 | 68.57% | 96 | 68.57% | +0 |
| DSP | 20 | 9.09% | 0 | 0.00% | +20 |

BRAM 사용량은 LCD framebuffer와 External BRAM 구조가 동일하기 때문에 두 버전이 같습니다. CNN_ALU는 주로 DSP와 일부 LUT/Register를 추가로 사용합니다.

## 주요 디렉터리

```text
FPGA_proj/
  cnn_alu.cpp / cnn_alu.h
  train_lenet_relu_maxpool.py
  export_lenet_int8.py
  firmware/
  mem/
  docs/

Pipeline/src/rtl/
  rv32i_cpu.v
  RV32I_AxiLite_Bram_Top.v
  RV32I_ExternalDmem_System.v
  cnn_alu/

Pipeline/board_demos/
  rv32i_lcd_success/
  rv32i_lcd_extbram_experiment/

Pipeline/vivado_board/
  Vivado build scripts
  programming scripts
  XSDB board test scripts
  implementation reports

Pipeline/sdk_app/
  PS-side sample applications
```

## 실행 및 재현

### CNN_ALU 포함 bitstream build

```powershell
cd Pipeline\vivado_board
$env:RV32I_ENABLE_CNN='1'
$env:RV32I_BUILD_NAME='cnn'
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source .\run_ps_lcd_extbram_bd_impl.tcl
```

### RV32I-only bitstream build

```powershell
cd Pipeline\vivado_board
$env:RV32I_ENABLE_CNN='0'
$env:RV32I_BUILD_NAME='no_cnn'
$env:RV32I_IMEM_HEX=(Resolve-Path '..\..\FPGA_proj\firmware\lenet_infer_no_cnn_imem.hex').Path
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source .\run_ps_lcd_extbram_bd_impl.tcl
```

### 0~9 보드 테스트

```powershell
cd Pipeline\vivado_board
xsdb .\xsdb_lcd_extbram_digits_0_to_9.tcl
```

자세한 실행 기록과 결과는 다음 문서를 참고하면 됩니다.

- `Pipeline/board_demos/rv32i_lcd_extbram_experiment/docs/BOARD_TEST_0_TO_9_RESULTS.md`
- `Pipeline/board_demos/rv32i_lcd_extbram_experiment/docs/RV32I_LCD_EXTBRAM_REPORT.md`
- `Pipeline/board_demos/rv32i_lcd_extbram_experiment/docs/RV32I_LCD_EXTBRAM_RUNBOOK.md`

## 사용 보드 및 도구

- Board: Zynq-7020 기반 FPGA 보드
- FPGA Tool: Vivado 2019.1
- CPU: custom RV32I pipeline CPU
- Accelerator: HLS 기반 CNN_ALU
- Display: 4.3-inch TFT-LCD
- Model: LeNet INT8

## 요약

이 프로젝트에서는 RV32I CPU에 CNN 전용 ALU를 추가하고, 이를 실제 Zynq 보드에 포팅해 LCD 출력까지 검증했습니다. 단순히 RTL 시뮬레이션에서 끝난 것이 아니라, 입력 이미지 로드, RV32I 실행, CNN_ALU 추론, LCD 결과 표시, cycle counter 기반 성능 측정까지 전체 흐름을 완성했습니다.
