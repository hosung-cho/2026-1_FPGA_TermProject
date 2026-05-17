# RV32I Data Memory Map

이 문서는 `lenet_int8_params.h`에서 추출한 INT8 weight, INT32 bias, requant multiplier를 RV32I data memory에 배치한 결과입니다.

## 1. 메모리 포맷

현재 `Pipeline/src/rtl/data_memory.v`는 32-bit word 배열입니다.

```text
reg [31:0] mem [0:DEPTH-1]
address = byte_address >> 2
word byte order = little-endian
```

INT8 weight 4개는 한 word에 다음 순서로 pack됩니다.

```text
byte address +0 -> word[7:0]
byte address +1 -> word[15:8]
byte address +2 -> word[23:16]
byte address +3 -> word[31:24]
```

INT32 bias와 multiplier는 signed 32-bit two's complement word로 저장됩니다.

## 2. 생성 파일

```text
mem/lenet_params.mem
mem/lenet_params_map.csv
mem/lenet_param_addr.h
docs/Memory_Map.md
```

## 3. 파라미터 메모리 사용량

```text
총 byte 수: 62436 bytes
총 word 수: 15609 words
기본 data_memory DEPTH: 16384 words (65536 bytes)
```

파라미터만 저장하는 경우 현재 16K-word data memory 안에 들어갑니다.

중간 feature map과 stack/data 영역까지 같은 data memory에 넣으려면 현재 64KB는 부족할 수 있습니다. 보드 통합에서는 다음 중 하나를 권장합니다.

```text
1. data_memory DEPTH를 32768 words 이상으로 확장
2. weight/bias는 별도 ROM/BRAM에 배치
3. feature map buffer를 overwrite 방식으로 재사용
```

## 4. 파라미터 배치

| Name | Type | Base Byte | Base Word | Size Bytes | Elements |
|---|---:|---:|---:|---:|---:|
| `conv1_weight_int8` | int8 | `0x00000000` | `0` | 150 | 150 |
| `conv1_bias_int32` | int32 | `0x00000098` | `38` | 24 | 6 |
| `conv1_requant_multiplier` | int32_scalar | `0x000000B0` | `44` | 4 | 1 |
| `conv2_weight_int8` | int8 | `0x000000B4` | `45` | 2400 | 2400 |
| `conv2_bias_int32` | int32 | `0x00000A14` | `645` | 64 | 16 |
| `conv2_requant_multiplier` | int32_scalar | `0x00000A54` | `661` | 4 | 1 |
| `conv3_weight_int8` | int8 | `0x00000A58` | `662` | 48000 | 48000 |
| `conv3_bias_int32` | int32 | `0x0000C5D8` | `12662` | 480 | 120 |
| `conv3_requant_multiplier` | int32_scalar | `0x0000C7B8` | `12782` | 4 | 1 |
| `fc1_weight_int8` | int8 | `0x0000C7BC` | `12783` | 10080 | 10080 |
| `fc1_bias_int32` | int32 | `0x0000EF1C` | `15303` | 336 | 84 |
| `fc1_requant_multiplier` | int32_scalar | `0x0000F06C` | `15387` | 4 | 1 |
| `fc2_weight_int8` | int8 | `0x0000F070` | `15388` | 840 | 840 |
| `fc2_bias_int32` | int32 | `0x0000F3B8` | `15598` | 40 | 10 |
| `fc2_requant_multiplier` | int32_scalar | `0x0000F3E0` | `15608` | 4 | 1 |

## 5. 펌웨어 접근 예시

```c
#include "lenet_param_addr.h"

int8_t w0 = load_i8(CONV1_WEIGHT_INT8_ADDR + offset);
int32_t b0 = load_i32(CONV1_BIAS_INT32_ADDR + oc * 4);
int32_t mult = load_i32(CONV1_REQUANT_MULTIPLIER_ADDR);
```

CNN_ALU의 `CMD_LOAD_A_PACK4`, `CMD_LOAD_W_PACK4`는 data memory load가 아닙니다. RV32I가 위 주소에서 기존 `LB/LW`로 값을 읽고, 4개 INT8을 pack한 뒤 CNN_ALU custom instruction으로 전달해야 합니다.
