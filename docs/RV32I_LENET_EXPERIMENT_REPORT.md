# RV32I + CNN_ALU LeNet 실습 결과 보고서

## 1. 실습 목적

본 실습의 목적은 RV32I CPU에 CNN 연산용 custom ALU인 `CNN_ALU`를 통합하고, MNIST LeNet INT8 추론을 end-to-end로 검증하는 것이다. 최종 목표는 RPS-Z7020-TK 보드의 Zynq PL 영역에 RV32I + CNN_ALU 시스템을 올려 실제 FPGA에서 LeNet 추론 결과를 확인하는 것이다.

현재까지 수행한 범위는 다음과 같다.

- LeNet 모델 학습 및 INT8 양자화
- CNN_ALU HLS 설계 및 Verilog RTL 생성
- RV32I CPU에 CNN_ALU custom instruction 경로 통합
- RV32I firmware 작성 및 instruction memory hex 생성
- MNIST digit 0~9 data memory image 생성
- Verilator 기반 RTL functional simulation
- CNN_ALU 사용 버전과 software-only baseline 성능 비교
- Vivado synthesis/place/route implementation 및 timing/resource 확인
- RPS-Z7020-TK 보드 포팅용 wrapper 및 XDC template 작성

아직 실제 보드 bitstream programming은 완료하지 않았다. 이유는 RPS-Z7020-TK 보드의 실제 `CLOCK`, `RESET`, `GPIO LED` package pin이 들어간 board XDC가 아직 확보되지 않았기 때문이다.

## 2. 사용 보드 및 타겟 디바이스

사용 예정 보드는 수업 자료 기준 `RPS-Z7020-TK`이다.

타겟 FPGA part:

```text
xc7z020clg484-1
```

Vivado implementation에서 사용한 설정:

```text
Device : xc7z020clg484-1
Clock  : 10.000 ns
Top    : RV32I_System
Tool   : Vivado 2019.1
```

보드 포팅용 top:

```text
Pipeline/src/rtl/RV32I_Board_Top.v
```

## 3. 설계 구성

### 3.1 RV32I CPU

`rv32i_cpu.v`는 5-stage pipeline 구조의 RV32I CPU이다. 기본 RV32I 명령어 실행에 더해 CNN_ALU를 호출하기 위한 custom instruction decode/control/data path를 추가하였다.

주요 기능:

- IF/ID/EX/MEM/WB pipeline
- branch flush
- load-use stall
- forwarding
- CNN_ALU custom instruction decode
- CNN_ALU busy/done 기반 pipeline stall

### 3.2 CNN_ALU

CNN_ALU는 HLS C++로 작성한 CNN 연산 가속 블록을 Vivado HLS로 Verilog 변환한 모듈이다.

주요 RTL:

```text
Pipeline/src/rtl/cnn_alu/CNN_ALU_Top.v
Pipeline/src/rtl/cnn_alu/CNN_ALU_Top_mac_mdEe.v
Pipeline/src/rtl/cnn_alu/CNN_ALU_Top_mux_3bkb.v
Pipeline/src/rtl/cnn_alu/CNN_ALU_Top_mux_8cud.v
Pipeline/src/rtl/cnn_alu/mac_pack4_delta.v
```

`mac_pack4_delta.v`는 MAC 연산을 4개 단위로 묶어 처리하기 위한 개선 모듈이다.

### 3.3 Memory 구성

Instruction memory는 `imem.hex`를 읽고, data memory는 `.mem` 파일을 읽어 초기화한다.

사용 firmware image:

```text
FPGA_proj/firmware/lenet_infer_imem.hex
```

MNIST digit별 data memory image:

```text
FPGA_proj/firmware/lenet_digit0_dmem.mem
...
FPGA_proj/firmware/lenet_digit9_dmem.mem
```

## 4. Firmware 구성

RV32I에서 실행되는 LeNet 추론 firmware는 다음 파일을 중심으로 구성된다.

```text
FPGA_proj/firmware/lenet_infer.c
FPGA_proj/firmware/cnn_alu_custom_ops.h
FPGA_proj/firmware/lenet_mem_map.h
FPGA_proj/firmware/startup.S
FPGA_proj/firmware/linker.ld
```

`lenet_infer.c`는 LeNet INT8 추론 순서를 수행하고, CNN 연산 구간에서는 CNN_ALU custom instruction을 호출한다.

비교를 위해 `CNN_ALU_DISABLE`을 정의한 software-only baseline firmware도 생성하였다.

```text
FPGA_proj/firmware/lenet_infer_no_cnn_imem.hex
```

## 5. Functional Simulation 결과

### 5.1 실행 환경

Verilator 기반 RTL simulation을 사용하였다.

실행 스크립트:

```powershell
cd Pipeline\testbench\testbench_LENET
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_lenet_0_to_9.ps1
```

Software-only baseline 실행:

```powershell
cd Pipeline\testbench\testbench_LENET
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_lenet_0_to_9_no_cnn.ps1
```

### 5.2 MNIST 0~9 검증 결과

MNIST digit 0부터 9까지 각각 하나의 sample을 넣어 RTL simulation을 수행하였다.

결과:

```text
digit0 PASS
digit1 PASS
digit2 PASS
digit3 PASS
digit4 PASS
digit5 PASS
digit6 PASS
digit7 PASS
digit8 PASS
digit9 PASS
```

즉, 현재 RTL functional simulation 기준으로 학습한 LeNet INT8 가중치와 MNIST 입력을 넣었을 때 digit 0~9 모두 올바르게 분류되었다.

## 6. Cycle 측정 결과

### 6.1 CNN_ALU 사용 버전

Verilator RTL simulation에서 측정한 CNN_ALU 사용 버전의 cycle 수는 다음과 같다.

```text
cycles per inference    : 8,625,963 ~ 8,625,966 cycles
average cycles          : 8,625,964.3 cycles
CNN custom instructions : 131,410 per image
CNN wait stall cycles   : 991,186 per image
load-use stall cycles   : 240,000 per image
total stall cycles      : 1,231,186 per image
flushes                 : about 419,906 ~ 419,909 per image
```

100 MHz 기준 추론 시간:

```text
8,625,964.3 cycles / 100,000,000 Hz = 약 0.08626 s
```

따라서 CNN_ALU 사용 시 한 장의 MNIST 이미지를 추론하는 데 약 `86.26 ms`가 걸린다.

### 6.2 CNN_ALU 미사용 software baseline

CNN_ALU를 사용하지 않고 RV32I software만으로 동일한 LeNet 추론을 수행한 결과는 다음과 같다.

```text
cycles per inference    : 86,036,124 ~ 86,101,621 cycles
average cycles          : 86,078,010.3 cycles
CNN custom instructions : 0
```

100 MHz 기준 추론 시간:

```text
86,078,010.3 cycles / 100,000,000 Hz = 약 0.86078 s
```

따라서 software-only baseline은 한 장의 MNIST 이미지를 추론하는 데 약 `860.78 ms`가 걸린다.

### 6.3 성능 비교

CNN_ALU 사용 버전과 software-only baseline의 평균 cycle을 비교하면 다음과 같다.

| 구분 | 평균 cycle | 100 MHz 기준 시간 |
|---|---:|---:|
| CNN_ALU 사용 | 8,625,964.3 | 약 86.26 ms |
| CNN_ALU 미사용 | 86,078,010.3 | 약 860.78 ms |

Speedup:

```text
86,078,010.3 / 8,625,964.3 = 약 9.98x
```

즉, CNN_ALU를 사용했을 때 RV32I software-only 대비 약 `9.98배` 빠른 추론 결과를 얻었다.

## 7. Vivado Implementation 결과

### 7.1 실행 명령

Vivado implementation은 다음 명령으로 수행하였다.

```powershell
cd Pipeline\vivado_impl
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source .\run_impl.tcl
```

### 7.2 Timing 결과

Post-route timing 결과:

```text
Clock period : 10.000 ns
WNS          : +0.231 ns
TNS          : 0.000 ns
Result       : Timing met
```

Worst path 기준:

```text
Requirement      : 10.000 ns
Data Path Delay  : 9.778 ns
Logic Delay      : 4.731 ns
Route Delay      : 5.047 ns
```

따라서 현재 구현은 `10 ns`, 즉 `100 MHz` clock constraint를 만족한다.

### 7.3 Resource 결과

Post-route resource 사용량:

| Resource | Used | Available | Utilization |
|---|---:|---:|---:|
| Slice LUTs | 3,113 | 53,200 | 5.85% |
| Slice Registers | 3,090 | 106,400 | 2.90% |
| Block RAM Tile | 32 | 140 | 22.86% |
| DSP | 16 | 220 | 7.27% |

Hierarchy 기준 주요 사용량:

```text
iDMem         : 32 BRAM tiles
iIMem         : 416 LUTs
icpu          : 2661 LUTs, 3090 FFs, 16 DSPs
i_cnn_alu_top : 1194 LUTs, 1481 FFs, 16 DSPs
```

## 8. Timing 개선 과정

초기 구현에서는 10 ns timing을 만족하지 못하는 문제가 있었다. 이를 해결하기 위해 다음 개선을 적용하였다.

1. `data_memory`를 asynchronous LUTRAM-style read에서 synchronous BRAM-style read로 변경
2. CPU에서 data memory read/write address를 분리
3. load data가 EX/MEM forwarding candidate path에 포함되지 않도록 수정
4. ALU adder를 hand-built ripple adder에서 carry-chain-friendly `+` 연산으로 변경
5. load/store address generation을 full ALU mux 경로가 아닌 dedicated `base + immediate` 경로로 분리
6. Vivado implementation script에서 `Explore`, `AggressiveExplore` directive 적용

이후 post-route 기준 WNS가 `+0.231 ns`로 개선되어 100 MHz timing을 만족하였다.

## 9. 보드 포팅 진행 상태

RPS-Z7020-TK 보드에 올리기 위한 wrapper를 작성하였다.

```text
Pipeline/src/rtl/RV32I_Board_Top.v
Pipeline/vivado_board/run_board_impl.tcl
Pipeline/vivado_board/board_template.xdc
```

`RV32I_Board_Top.v`는 외부 포트를 최소화하고 LED로 결과를 확인하도록 구성하였다.

LED mapping:

| LED | 의미 |
|---|---|
| LED[0] | LeNet 추론 완료 |
| LED[4:1] | 예측 digit |
| LED[5] | digit7 입력 기준 PASS |
| LED[6] | digit7 입력 기준 FAIL |
| LED[7] | heartbeat |

현재 보드 bitstream 생성은 아직 완료하지 않았다. 이유는 실제 RPS-Z7020-TK board pin assignment가 필요하기 때문이다.

현재 확보한 `FPGA_proj/top.xdc`는 board pin mapping 파일이 아니라 ILA debug core 연결용 constraints이다. 따라서 `CLOCK_50`, `reset`, `LED[7:0]`의 `PACKAGE_PIN`을 지정하는 XDC로 사용할 수 없다.

필요한 추가 자료:

```text
RPS-Z7020-TK board master XDC
또는 RPS-Z7020-TK schematic / pin assignment table
```

최소 필요 핀:

```text
PL clock pin
reset button pin
GPIO LED[7:0] pins
```

## 10. 현재 결론

현재까지의 실습 결론은 다음과 같다.

1. RV32I CPU와 CNN_ALU custom instruction 통합이 완료되었다.
2. LeNet INT8 firmware가 RV32I에서 실행되도록 구성되었다.
3. MNIST digit 0~9 RTL functional simulation에서 모두 PASS하였다.
4. CNN_ALU 사용 시 평균 `8,625,964.3 cycles`가 소요되었다.
5. CNN_ALU 미사용 software baseline은 평균 `86,078,010.3 cycles`가 소요되었다.
6. CNN_ALU 적용으로 약 `9.98x`의 cycle 개선을 확인하였다.
7. Vivado post-route implementation에서 `10 ns` timing을 만족하였다.
8. Resource 사용량은 LUT `5.85%`, FF `2.90%`, BRAM `22.86%`, DSP `7.27%` 수준이다.
9. 실제 RPS-Z7020-TK 보드 programming은 board XDC 확보 후 진행해야 한다.

## 11. 다음 진행 계획

다음 단계는 실제 FPGA 보드 검증이다.

1. RPS-Z7020-TK의 master XDC 또는 schematic 확보
2. `Pipeline/vivado_board/board_template.xdc`를 `board.xdc`로 완성
3. `run_board_impl.tcl`로 board bitstream 생성
4. Vivado Hardware Manager로 보드 programming
5. LED heartbeat 및 digit7 PASS/FAIL 확인
6. 이후 DIP switch로 digit0~9 선택 기능 추가
7. UART 또는 Text LCD로 추론 결과 출력 확장

