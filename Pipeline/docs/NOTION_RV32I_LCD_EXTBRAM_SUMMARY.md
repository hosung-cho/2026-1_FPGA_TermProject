# RV32I + LCD + External BRAM 구조 정리

## 1. 프로젝트 목표

본 프로젝트는 RV32I 기반 LeNet INT8 추론기를 Zynq-7020 보드에 포팅하고, 추론 결과를 보드 내장 4.3인치 TFT-LCD에 표시하는 것을 목표로 한다.

초기 버전은 하나의 digit-7 입력 이미지를 고정된 data memory로 실행하는 구조였고, LCD 출력까지 정상 동작하는 것을 확인했다. 이후 발표 완성도와 확장성을 높이기 위해 data memory를 외부 BRAM 구조로 분리했다.

외부 BRAM 구조의 핵심 목적은 PS가 실행 전에 입력 데이터를 BRAM에 직접 로드하고, RV32I CPU가 해당 BRAM을 data memory처럼 사용하도록 만드는 것이다. 이를 통해 여러 이미지 데이터를 순차적으로 넣고 결과를 LCD에 표시하는 확장이 가능해진다.

## 2. 최종 Block Design 개요

전체 구조는 다음과 같다.

```text
Zynq PS
  -> AXI Interconnect
     -> RV32I control/status AXI-Lite
     -> AXI BRAM Controller + External dmem BRAM
     -> TFT-LCD AXI framebuffer
```

PS는 AXI master 역할을 수행하고, PL 내부의 RV32I 제어 레지스터, 외부 BRAM, LCD framebuffer에 접근한다.

## 3. Address Map

| Peripheral | Base Address | Range | Purpose |
| --- | ---: | ---: | --- |
| RV32I control/status | `0x43C00000` | 64 KB | 실행 제어, 상태 확인, 추론 결과 확인 |
| External dmem BRAM | `0x43C40000` | 128 KB | RV32I data memory 이미지 로드 |
| TFT-LCD framebuffer | `0x43C80000` | 512 KB | LCD 화면 픽셀 데이터 저장 |

RV32I 제어 레지스터에는 추론 cycle 측정을 위한 `cycle_count`도 추가했다.

| Offset | Register | Purpose |
| ---: | --- | --- |
| `0x2C` | `cycle_count` | run 시작부터 done 발생까지의 cycle 수 |

## 4. PS와 PL의 역할

PS는 실행 제어와 데이터 로드를 담당한다.

```text
1. PS가 0x43C40000 주소에 dmem 이미지를 로드
2. PS가 0x43C00000 control register에 run enable 기록
3. RV32I가 BRAM에 저장된 data memory를 사용해 LeNet 추론 수행
4. PS 또는 LCD 제어 로직이 결과를 LCD framebuffer에 반영
5. LCD에 예측 digit 표시
```

PL은 실제 연산과 출력 하드웨어를 담당한다.

```text
RV32I CPU
External dmem BRAM
AXI BRAM Controller
TFT-LCD framebuffer
LCD timing generator
```

## 5. External BRAM 구조

기존 구조에서는 RV32I data memory가 CPU wrapper 내부에 가까운 형태였기 때문에 입력 데이터를 쉽게 교체하기 어려웠다.

새 구조에서는 data memory를 `Block Memory Generator` 기반의 외부 BRAM으로 분리했다.

```text
blk_mem_gen dmem_bram_0
  - True Dual Port RAM
  - 32-bit data width
  - 32768 word depth
  - total 128 KB
```

BRAM 포트 역할은 다음과 같다.

| BRAM Port | Role |
| --- | --- |
| Port A | PS 로드 또는 CPU write 공유 |
| Port B | CPU read 전용 |

## 6. AXI BRAM Controller 역할

`axi_bram_ctrl_0`는 PS가 AXI 주소 공간으로 BRAM에 접근할 수 있게 해주는 변환기다.

PS는 `0x43C40000` 주소에 일반 AXI write/read를 수행한다. AXI BRAM Controller는 이 접근을 BRAM native port 신호로 변환한다.

즉 PS 입장에서는 BRAM이 메모리맵된 주변장치처럼 보이고, RV32I 입장에서는 일반 data memory처럼 보인다.

## 7. BramPortA_RunMux 역할

외부 BRAM 구조에서 가장 중요한 모듈은 `BramPortA_RunMux`이다.

이 모듈은 BRAM Port A를 누가 사용할지 선택한다.

```text
cpu_active = 0
  PS -> AXI BRAM Controller -> BRAM Port A
  입력 데이터 로드 가능

cpu_active = 1
  RV32I CPU write -> BRAM Port A
  CPU 실행 중 store 가능
```

즉 실행 전에는 PS가 BRAM에 입력 데이터를 넣고, 실행 중에는 CPU가 BRAM에 결과나 중간 데이터를 쓸 수 있다.

CPU read는 Port B를 사용하므로 실행 중에도 독립적인 read path를 가진다.

## 8. LCD 출력 구조

`TFTLCD_AxiLite_Top`은 AXI-Lite framebuffer와 LCD timing generator를 포함한다.

PS가 `0x43C80000` framebuffer 영역에 RGB565 픽셀 데이터를 쓰면, LCD 블록은 해당 데이터를 읽어서 실제 LCD 핀으로 출력한다.

외부 LCD 핀은 다음과 같다.

```text
opclk
Vsync
Hsync
R[4:0]
G[5:0]
B[4:0]
TFTLCD_DE_out
TFTLCD_Tpower
```

검증 과정에서 LCD timing과 framebuffer line address를 수정하여 안정적인 세로 컬러바와 digit 표시를 확인했다.

## 9. 기존 구조와 외부 BRAM 구조 비교

| Item | 기존 LCD 성공 구조 | External BRAM 구조 |
| --- | --- | --- |
| dmem 위치 | RV32I wrapper 내부에 가까움 | Block Design의 외부 BRAM |
| 입력 교체 | 빌드/초기화 의존성이 큼 | PS가 AXI로 BRAM에 직접 로드 |
| 다중 이미지 확장 | 불편함 | 쉬움 |
| BD 가시성 | 단순함 | 메모리 구조가 명확히 보임 |
| 발표 적합성 | 단일 성공 데모 | 확장 가능한 시스템 구조 설명 가능 |

## 10. 검증 결과

외부 BRAM 구조는 Vivado implementation과 실제 보드 실행을 모두 통과했다.

빌드 결과:

```text
RV32I_PS_LCD_EXTBRAM_BD_WNS=0.085
RV32I_PS_LCD_EXTBRAM_BD_TIMING_OK=1
RV32I_PS_LCD_EXTBRAM_BD_IMPL_OK=1
```

보드 실행 결과:

```text
EXTBRAM_DMEM_WORDS_WRITTEN=32768
EXTBRAM_DMEM_BASEADDR=0x43C40000
EXTBRAM_CYCLE_COUNT=<measured cycles>
EXTBRAM_LATENCY_US_AT_100MHZ=<cycle_count / 100>
EXTBRAM_PRED=7
EXTBRAM_EXPECTED=7
EXTBRAM_PASS=1
```

LCD 출력도 digit 7이 정상적으로 표시되는 것을 확인했다.

추론 시간은 cycle counter 기반으로 계산한다. 현재 PL 동작 주파수는 100 MHz이므로 계산식은 다음과 같다.

```text
latency_seconds = cycle_count / 100,000,000
latency_us      = cycle_count / 100
```

## 11. 구현 중 해결한 문제

초기 외부 BRAM 설계에서는 `blk_mem_gen`이 32768 word가 아니라 2048 word로 잡히는 문제가 있었다. 이 경우 LeNet dmem 전체를 담을 수 없어 CPU가 정상적으로 완료되지 않았다.

해결 방법은 `blk_mem_gen`을 `BRAM_Controller` 모드가 아니라 독립적인 `Stand_Alone` native memory로 설정하는 것이었다.

핵심 설정:

```tcl
CONFIG.use_bram_block {Stand_Alone}
CONFIG.Interface_Type {Native}
CONFIG.Memory_Type {True_Dual_Port_RAM}
CONFIG.Write_Depth_A {32768}
CONFIG.Enable_32bit_Address {false}
```

이후 BRAM은 32768 x 32-bit로 정상 설정되었고, 실제 보드에서도 추론 결과가 정상적으로 나왔다.

## 12. 향후 확장 방향

현재는 digit-7 dmem 이미지를 로드하여 결과가 정상적으로 나오는 것을 확인했다.

다음 단계는 여러 입력 이미지에 대해 dmem 파일을 준비하고, PS 또는 XSDB 스크립트에서 순차적으로 BRAM에 로드한 뒤 결과를 LCD에 표시하는 방식으로 확장하는 것이다.

예상 시나리오:

```text
image 0 dmem load -> RV32I run -> LCD result
image 1 dmem load -> RV32I run -> LCD result
image 2 dmem load -> RV32I run -> LCD result
...
```

이 구조를 사용하면 발표 시 단일 이미지가 아니라 여러 이미지에 대해 추론 결과가 정상적으로 출력되는 것을 보여줄 수 있다.
