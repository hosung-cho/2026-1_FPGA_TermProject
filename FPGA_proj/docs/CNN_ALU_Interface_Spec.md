# CNN_ALU 인터페이스 명세서

이 문서는 RV32I 파이프라인과 HLS로 생성한 `CNN_ALU_Top` RTL을 통합하기 위한 포트, 명령어, 호출 규약을 정리한 명세서입니다.

## 1. 모듈 개요

`CNN_ALU_Top`은 LeNet-5 계열 INT8 추론을 위한 tightly-coupled CNN ALU입니다. 전체 layer를 독립적으로 실행하는 accelerator가 아니라, RV32I가 activation/weight를 가져와 4개씩 pack해서 넣어주면 내부 버퍼에 저장한 뒤 MAC, pooling, bias, requant를 수행하는 연산 유닛입니다.

현재 지원하는 주요 기능은 다음과 같습니다.

```text
INT8 activation/weight pack4 load
32-slot padded 5x5 MAC
multi-channel / FC 누적 MAC
INT32 bias add
ReLU
2x2 MaxPool
INT32 -> INT8 requant + ReLU
result readback
```

## 2. HLS Top 포트

HLS C top 함수:

```cpp
void CNN_ALU_Top(
    ap_uint<32> rs1_data,
    ap_uint<4>  cnn_op,
    ap_uint<32> *rd_data
);
```

합성 후 RTL 포트:

```text
ap_clk          input   1
ap_rst          input   1
ap_start        input   1
ap_done         output  1
ap_idle         output  1
ap_ready        output  1
rs1_data_V      input   32
cnn_op_V        input   4
rd_data_V       output  32
```

포트 의미:

```text
rs1_data_V:
  RV32I rs1 값 또는 immediate-like operand를 전달하는 32-bit 입력입니다.
  LOAD_A/LOAD_W에서는 INT8 4개가 packed된 값입니다.
  ADD_BIAS에서는 signed INT32 bias입니다.
  REQUANT_RELU에서는 signed INT32 requant multiplier입니다.

cnn_op_V:
  CNN_ALU 내부 동작을 선택하는 4-bit opcode입니다.
  RV32I 표준 opcode 필드와 같은 것이 아니라, decoder/wrapper가 만들어 CNN_ALU에 넘기는 내부 제어 신호입니다.

rd_data_V:
  GET_RES 명령에서 acc_reg 값을 RV32I writeback 경로로 반환합니다.

ap_start/ap_done:
  HLS ap_ctrl_hs handshake입니다.
  custom instruction이 EX stage에서 실행될 때 ap_start를 1-cycle pulse로 주고, ap_done이 올 때까지 pipeline stall을 걸어야 합니다.
```

## 3. CNN Opcode 표

현재 `cnn_op`는 10개 동작을 표현하므로 4비트가 필요합니다.

```cpp
#define CMD_LOAD_W_PACK4 0
#define CMD_LOAD_A_PACK4 1
#define CMD_START_MAC    2
#define CMD_GET_RES      3
#define CMD_START_POOL   4
#define CMD_CLEAR_ACC    5
#define CMD_ACC_MAC      6
#define CMD_APPLY_RELU   7
#define CMD_ADD_BIAS     8
#define CMD_REQUANT_RELU 9
#define REQUANT_SHIFT    20
```

명령별 동작:

```text
0 CMD_LOAD_W_PACK4
  rs1_data[7:0], [15:8], [23:16], [31:24]를 signed INT8 weight 4개로 해석하여 weight_buf에 저장합니다.

1 CMD_LOAD_A_PACK4
  rs1_data[7:0], [15:8], [23:16], [31:24]를 signed INT8 activation 4개로 해석하여 act_buf에 저장합니다.

2 CMD_START_MAC
  현재 act_buf와 weight_buf의 32-slot padded dot product를 계산하여 acc_reg에 저장합니다.
  ReLU나 bias는 적용하지 않습니다.

3 CMD_GET_RES
  현재 acc_reg를 rd_data로 반환합니다.

4 CMD_START_POOL
  act_buf[0..3]의 2x2 MaxPool 결과를 acc_reg에 저장합니다.

5 CMD_CLEAR_ACC
  acc_reg, weight pointer, activation pointer를 0으로 초기화합니다.

6 CMD_ACC_MAC
  현재 32-slot padded dot product를 acc_reg에 누적합니다.
  C2/C3/FC처럼 여러 channel 또는 여러 chunk를 누적할 때 사용합니다.

7 CMD_APPLY_RELU
  acc_reg가 음수면 0으로 만듭니다.
  현재 LeNet INT8 inference 경로에서는 보통 CMD_REQUANT_RELU를 쓰므로 단독 사용 빈도는 낮습니다.

8 CMD_ADD_BIAS
  rs1_data 전체를 signed INT32 bias로 해석하여 acc_reg에 더합니다.

9 CMD_REQUANT_RELU
  rs1_data를 signed INT32 multiplier로 해석합니다.
  acc_reg를 다음 수식으로 INT8 activation 범위로 줄입니다.
  acc_reg = clamp_relu(round(acc_reg * multiplier / 2^20))
```

## 4. RISC-V Encoding 제안

RV32I 기본 `opcode`와 `cnn_op`는 다른 개념입니다.

```text
opcode:
  RISC-V instruction의 7-bit 큰 분류 필드입니다.

cnn_op:
  CNN_ALU 내부 동작 선택용 4-bit 제어 신호입니다.
```

권장 방식:

```text
opcode == CUSTOM_0이면 CNN custom instruction으로 인식
cnn_op[2:0] = funct3
cnn_op[3]   = funct7[0]
```

이렇게 하면 CNN_ALU 동작 0~15까지 표현할 수 있습니다. 현재 명령 0~9를 모두 담을 수 있습니다.

예:

```text
funct7[0]=0, funct3=000 -> cnn_op=0 -> CMD_LOAD_W_PACK4
funct7[0]=1, funct3=001 -> cnn_op=9 -> CMD_REQUANT_RELU
```

## 5. Pack4 데이터 규약

`LOAD_A_PACK4`, `LOAD_W_PACK4`에서 `rs1_data`는 다음과 같이 해석합니다.

```text
rs1_data[7:0]    -> lane0, signed INT8
rs1_data[15:8]   -> lane1, signed INT8
rs1_data[23:16]  -> lane2, signed INT8
rs1_data[31:24]  -> lane3, signed INT8
```

예:

```text
pack4(-1, 2, -3, 4)
  lane0 = -1
  lane1 = 2
  lane2 = -3
  lane3 = 4
```

## 6. 5x5 MAC Padding 규약

하드웨어 내부 버퍼는 32-slot입니다. 실제 5x5 유효 데이터는 25개이고, 나머지 7개는 하드웨어에서 0으로 정리합니다.

소프트웨어 규약:

```text
각 MAC chunk마다 논리적으로 25-slot까지 LOAD_A/LOAD_W를 호출해야 합니다.
마지막 packet은 slot 24를 포함해야 합니다.
slot 24 처리 시 하드웨어가 slot 25~31을 0으로 지웁니다.
```

FC 마지막 chunk처럼 실제 값이 20개만 있는 경우:

```text
20~24 slot은 소프트웨어가 0으로 채워 전송
25~31 slot은 하드웨어가 0으로 clear
```

## 7. 명령 호출 예시

단일 5x5 convolution output 하나:

```text
CMD_CLEAR_ACC

LOAD_A_PACK4 x 7회
LOAD_W_PACK4 x 7회
CMD_ACC_MAC

CMD_ADD_BIAS        rs1_data = bias_int32
CMD_REQUANT_RELU    rs1_data = layer_requant_multiplier
CMD_GET_RES
```

C2/C3처럼 input channel이 여러 개인 경우:

```text
CMD_CLEAR_ACC

for each input channel:
  LOAD_A_PACK4 x 7회
  LOAD_W_PACK4 x 7회
  CMD_ACC_MAC

CMD_ADD_BIAS
CMD_REQUANT_RELU
CMD_GET_RES
```

2x2 MaxPool 하나:

```text
CMD_CLEAR_ACC
CMD_LOAD_A_PACK4    rs1_data = pack4(p0, p1, p2, p3)
CMD_START_POOL
CMD_GET_RES
```

FC2 output logit 하나:

```text
CMD_CLEAR_ACC

for each 25-value chunk:
  LOAD_A_PACK4 x 7회
  LOAD_W_PACK4 x 7회
  CMD_ACC_MAC

CMD_ADD_BIAS
CMD_GET_RES
```

FC2는 최종 argmax용 logit이므로 현재 권장 방식에서는 `CMD_REQUANT_RELU`를 생략하고 INT32 logit 10개를 그대로 비교합니다.

## 8. Layer별 Requant Multiplier

`lenet_int8_params.h`에 자동 생성되어 있습니다.

```cpp
#define LENET_REQUANT_SHIFT 20

static const int32_t conv1_requant_multiplier = 827;
static const int32_t conv2_requant_multiplier = 1994;
static const int32_t conv3_requant_multiplier = 1663;
static const int32_t fc1_requant_multiplier = 2621;
static const int32_t fc2_requant_multiplier = 2840;
```

현재 inference driver에서는 FC2 requant를 사용하지 않고 INT32 logit을 비교합니다.

## 9. 통합 시 주의사항

```text
1. cnn_op는 4비트입니다. funct3 3비트만으로는 부족합니다.
2. CNN LOAD_A/W는 data memory load가 아닙니다. register -> CNN_ALU internal buffer write입니다.
3. GET_RES 결과를 memory에 저장하려면 기존 RV32I SB/SW를 사용해야 합니다.
4. ap_done까지 pipeline stall이 필요합니다.
5. ADD_BIAS는 반드시 MAC/ACC_MAC 이후, REQUANT_RELU 이전에 호출해야 합니다.
6. FC2는 ReLU를 적용하지 않고 INT32 logits argmax를 권장합니다.
```
