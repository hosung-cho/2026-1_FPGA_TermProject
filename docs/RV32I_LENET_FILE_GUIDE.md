# RV32I + CNN_ALU LeNet Project File Guide

이 문서는 RV32I CPU, CNN_ALU, LeNet 추론 펌웨어, 시뮬레이션, Vivado 구현에 필요한 주요 파일의 역할을 정리한 문서입니다.

## 1. RTL Source

### `Pipeline/src/rtl/basic_modules.v`

RV32I CPU에서 사용하는 기본 조합/순차 모듈이 들어 있습니다. ALU 주변의 기본 연산 블록과 파이프라인 구성에 필요한 공통 모듈이 포함됩니다.

### `Pipeline/src/rtl/rv32i_cpu.v`

RV32I 파이프라인 CPU 본체입니다. 기본 RV32I 명령어 실행 경로와 함께 CNN_ALU를 호출하기 위한 custom instruction decode/control/data path가 포함됩니다.

주요 역할:

- instruction fetch/decode/execute/memory/writeback 파이프라인 구성
- load-use stall, branch flush, forwarding 처리
- custom instruction을 CNN_ALU 입력으로 전달
- CNN_ALU done까지 pipeline을 stall하는 제어 포함

### `Pipeline/src/rtl/inst_memory.v`

명령어 메모리입니다. `imem.hex`를 `$readmemh`로 읽어서 RV32I 프로그램을 공급합니다.

보드/Vivado 실행 시에는 Tcl 스크립트가 `FPGA_proj/firmware/lenet_infer_imem.hex`를 `imem.hex`로 복사해서 사용합니다.

### `Pipeline/src/rtl/data_memory.v`

데이터 메모리입니다. LeNet 입력 이미지, 가중치, 중간 feature map, 결과 저장 영역이 이 메모리에 배치됩니다.

주요 특징:

- byte enable 지원
- read/write address 분리
- `INIT_FILE` 파라미터로 `.mem` 초기화 파일 로드 가능

### `Pipeline/src/rtl/RV32I_System.v`

RV32I CPU, instruction memory, data memory를 묶은 system top입니다.

주요 역할:

- CPU와 IMEM/DMEM 연결
- debug signal 출력
- `CPU_RESET_PC` 파라미터 지원
- `DMEM_INIT_FILE` 파라미터로 보드용 DMEM 초기화 지원

### `Pipeline/src/rtl/RV32I_Board_Top.v`

RPS-Z7020-TK 보드에 올리기 위한 board top wrapper입니다. 기존 `RV32I_System`의 많은 debug 포트를 외부 핀으로 빼지 않고, 보드 LED만 사용해서 실행 상태를 확인합니다.

LED 의미:

- `LED[0]`: LeNet 추론 완료
- `LED[4:1]`: 예측 digit
- `LED[5]`: digit7 입력 기준 PASS
- `LED[6]`: digit7 입력 기준 FAIL
- `LED[7]`: heartbeat

## 2. CNN_ALU RTL

### `Pipeline/src/rtl/cnn_alu/CNN_ALU_Top.v`

HLS에서 생성된 CNN_ALU 최상위 Verilog입니다. RV32I CPU custom instruction 경로에서 호출되는 연산 블록입니다.

### `Pipeline/src/rtl/cnn_alu/CNN_ALU_Top_mac_mdEe.v`

CNN_ALU 내부 MAC 연산 모듈입니다. timing critical path와 가장 관련이 큰 블록입니다.

### `Pipeline/src/rtl/cnn_alu/CNN_ALU_Top_mux_3bkb.v`

CNN_ALU 내부 mux 계층 중 하나입니다. HLS가 생성한 보조 RTL입니다.

### `Pipeline/src/rtl/cnn_alu/CNN_ALU_Top_mux_8cud.v`

CNN_ALU 내부 mux 계층 중 하나입니다. HLS가 생성한 보조 RTL입니다.

### `Pipeline/src/rtl/cnn_alu/mac_pack4_delta.v`

4개 단위 MAC 연산을 묶어 처리하기 위해 추가/개선된 MAC helper 모듈입니다. CNN_ALU 성능 개선과 관련된 핵심 RTL 중 하나입니다.

## 3. LeNet Firmware

### `FPGA_proj/firmware/lenet_infer.c`

RV32I에서 실행되는 LeNet 추론 프로그램입니다. 이미지, 가중치, feature map을 data memory에 두고 CNN_ALU custom instruction을 호출해 추론을 수행합니다.

### `FPGA_proj/firmware/lenet_mem_map.h`

LeNet 추론에 사용하는 data memory 주소 맵입니다.

예:

- 입력 이미지 주소
- 가중치/바이어스 주소
- 중간 feature map 주소
- 결과 저장 주소
- done flag 주소

### `FPGA_proj/firmware/cnn_alu_custom.h`

CNN_ALU custom instruction 호출에 필요한 상위 매크로/함수 선언 파일입니다.

### `FPGA_proj/firmware/cnn_alu_custom_ops.h`

CNN_ALU custom instruction inline 구현 파일입니다. `CNN_ALU_DISABLE`을 정의하면 CNN_ALU 없이 software fallback으로도 실행할 수 있습니다.

### `FPGA_proj/firmware/cnn_alu_custom_ops.S`

custom instruction 호출을 assembly 레벨에서 분리해둔 파일입니다.

### `FPGA_proj/firmware/startup.S`

RV32I bare-metal 프로그램 시작 코드입니다. reset 이후 stack 설정, C entry 호출 등을 담당합니다.

### `FPGA_proj/firmware/linker.ld`

RV32I firmware용 linker script입니다. code/data 배치 주소를 정의합니다.

### `FPGA_proj/firmware/Makefile`

RISC-V GCC로 firmware를 빌드하는 Makefile입니다.

생성 대상:

- ELF
- binary
- IMEM hex
- CNN_ALU 사용 버전
- no-CNN baseline 버전

### `FPGA_proj/firmware/bin_to_imem_hex.ps1`

RISC-V binary를 instruction memory용 hex 형식으로 변환하는 PowerShell 스크립트입니다.

### `FPGA_proj/firmware/make_lenet_dmem.ps1`

LeNet 입력/가중치/파라미터를 data memory 초기화 `.mem` 파일로 만드는 스크립트입니다.

### `FPGA_proj/firmware/lenet_infer_imem.hex`

CNN_ALU를 사용하는 LeNet 추론 firmware의 instruction memory 이미지입니다. RTL simulation과 Vivado 구현에서 사용됩니다.

### `FPGA_proj/firmware/lenet_infer_no_cnn_imem.hex`

CNN_ALU를 사용하지 않는 software baseline firmware의 instruction memory 이미지입니다. CNN_ALU 적용 전후 성능 비교에 사용됩니다.

### `FPGA_proj/firmware/lenet_digit0_dmem.mem` ~ `lenet_digit9_dmem.mem`

MNIST digit 0부터 9까지 각각 하나의 샘플을 포함한 data memory 초기화 파일입니다. 각 파일에는 입력 이미지, LeNet int8 가중치, scale, bias, working buffer 초기값이 들어갑니다.

## 4. Model Parameters and Export Scripts

### `FPGA_proj/lenet_int8_params.h`

학습된 LeNet 모델을 int8로 변환한 C header입니다. HLS C simulation과 firmware 생성에 사용됩니다.

### `FPGA_proj/lenet_int8_scales.txt`

int8 quantization에 필요한 scale 정보입니다.

### `FPGA_proj/mem/lenet_param_addr.h`

LeNet parameter가 data memory에 배치되는 주소를 정의한 header입니다.

### `FPGA_proj/mem/lenet_params.mem`

LeNet 가중치/바이어스/scale을 memory initialization 형식으로 export한 파일입니다.

### `FPGA_proj/mem/lenet_params_map.csv`

각 parameter 이름과 memory address mapping을 기록한 CSV입니다. 디버깅과 문서화에 사용됩니다.

### `FPGA_proj/train_lenet_relu_maxpool.py`

MNIST LeNet 모델을 학습하는 Python 스크립트입니다.

### `FPGA_proj/export_lenet_int8.py`

학습된 모델을 int8 parameter/header 형식으로 export하는 스크립트입니다.

### `FPGA_proj/export_rv32i_mem.py`

RV32I data memory에서 사용할 `.mem` 파일과 memory map을 생성하는 스크립트입니다.

## 5. HLS Source and Testbench

### `FPGA_proj/cnn_alu.cpp`

CNN_ALU HLS C++ 원본입니다. CNN 연산을 custom ALU 형태로 만들기 위한 핵심 소스입니다.

### `FPGA_proj/cnn_alu.h`

CNN_ALU HLS 함수 인터페이스와 타입 정의가 들어 있습니다.

### `FPGA_proj/tb_cnn_alu.cpp`

CNN_ALU 단독 동작 검증용 C++ testbench입니다.

### `FPGA_proj/tb_lenet_int8_cnn_alu.cpp`

LeNet int8 연산을 CNN_ALU 기반으로 검증하는 C++ testbench입니다.

### `FPGA_proj/run_csim.tcl`

Vivado HLS C simulation 실행 스크립트입니다.

### `FPGA_proj/run_csynth.tcl`

Vivado HLS C synthesis 실행 스크립트입니다.

### `FPGA_proj/run_lenet_csim.tcl`

LeNet 전체 흐름을 HLS C simulation으로 검증하는 Tcl 스크립트입니다.

## 6. RTL Simulation

### `Pipeline/testbench/testbench_LENET/RV32I_System_tb.v`

RV32I system 전체를 검증하는 Verilog testbench입니다.

주요 기능:

- IMEM hex plusarg 지원
- DMEM hex plusarg 지원
- MNIST sample 이름 출력
- LeNet 결과/done flag 감시
- cycle count 측정
- CNN_ALU start/done count 측정
- stall/flush count 측정

### `Pipeline/testbench/testbench_LENET/Makefile.verilator`

Verilator로 `RV32I_System_tb.v`를 빌드하기 위한 Makefile입니다.

### `Pipeline/testbench/testbench_LENET/run_lenet_0_to_9.ps1`

CNN_ALU 사용 firmware로 MNIST digit 0부터 9까지 RTL simulation을 실행하는 PowerShell 스크립트입니다.

### `Pipeline/testbench/testbench_LENET/run_lenet_0_to_9_no_cnn.ps1`

CNN_ALU를 사용하지 않는 software baseline firmware로 digit 0부터 9까지 RTL simulation을 실행하는 PowerShell 스크립트입니다.

### `Pipeline/testbench/testbench_LENET/run_verilator_wsl.sh`

WSL 환경에서 Verilator simulation을 실행하기 위한 shell script입니다.

### `Pipeline/testbench/testbench_LENET/lenet_mem_map.vh`

Verilog testbench에서 LeNet memory address를 참조하기 위한 include file입니다.

### `Pipeline/testbench/testbench_LENET/README.md`

LeNet RTL simulation 실행 방법과 결과 확인 방법을 정리한 문서입니다.

## 7. Vivado Implementation

### `Pipeline/vivado_impl/run_impl.tcl`

`xc7z020clg484-1` target part로 synthesis/place/route/timing report를 실행하는 Vivado batch script입니다. 실제 보드 핀 제약 없이 timing/resource 확인용으로 사용합니다.

### `Pipeline/vivado_impl/README.md`

Vivado implementation 결과, timing, resource, CNN_ALU/no-CNN 성능 비교를 정리한 문서입니다.

### `Pipeline/vivado_board/run_board_impl.tcl`

실제 RPS-Z7020-TK 보드에 올리기 위한 Vivado batch script입니다. `board.xdc`가 있어야 bitstream 생성을 진행합니다.

### `Pipeline/vivado_board/board_template.xdc`

RPS-Z7020-TK 보드용 XDC를 만들기 위한 템플릿입니다. 실제 package pin은 아직 비어 있으므로, 보드의 `top.xdc`, master XDC, schematic에서 확인해 채워야 합니다.

### `Pipeline/vivado_board/README.md`

보드 구현 흐름과 LED mapping, `board.xdc` 필요성을 정리한 문서입니다.

## 8. Reference Documents

### `FPGA_proj/docs/CNN_ALU_Interface_Spec.md`

CNN_ALU interface와 RV32I custom instruction 연동 방식을 설명한 문서입니다.

### `FPGA_proj/docs/HLS_Result_Summary.md`

HLS synthesis 결과와 CNN_ALU 구조를 요약한 문서입니다.

### `FPGA_proj/docs/Memory_Map.md`

LeNet data memory map을 설명한 문서입니다.

### `FPGA_proj/docs/RV32I_Firmware_Pseudocode.md`

RV32I firmware의 LeNet 추론 흐름을 pseudocode로 정리한 문서입니다.

### `docs/Text LCD (FPGA Programming).pdf`

수업에서 사용한 RPS-Z7020-TK / Zynq PL programming 실습 자료입니다. 보드 모델 확인에는 도움이 되지만, 실제 pin assignment 값은 포함되어 있지 않습니다.

## 9. Do Not Upload

아래 파일/폴더는 빌드 산출물이거나 캐시이므로 GitHub에 올리지 않는 것을 권장합니다.

```text
FPGA_proj/__pycache__/
FPGA_proj/cnn_alu_hls_prj/*/csim/build/
FPGA_proj/cnn_alu_hls_prj/*/impl/
FPGA_proj/cnn_alu_hls_prj/*/syn/
FPGA_proj/cnn_alu_lenet_hls_prj/*/csim/build/
Pipeline/testbench/testbench_LENET/obj_dir/
Pipeline/testbench/testbench_LENET/*.vvp
Pipeline/vivado_impl/build/
Pipeline/vivado_impl/*.jou
Pipeline/vivado_impl/vivado*.log
Pipeline/vivado_impl/imem.hex
```

Vivado report 파일은 결과 증빙이 필요하면 업로드해도 되지만, repository를 가볍게 유지하려면 `README.md`에 주요 수치만 남기고 제외하는 편이 좋습니다.
