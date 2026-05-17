# RV32I 펌웨어 Pseudocode

이 문서는 RV32I가 data memory에 있는 INT8 activation/weight, INT32 bias, requant multiplier를 읽어 CNN_ALU custom instruction으로 LeNet-5 INT8 추론을 수행하는 흐름을 정리합니다.

## 1. 기본 데이터 흐름

현재 구조에서 전체 모델 데이터는 RV32I 쪽 메모리에 있습니다.

```text
Data memory:
  input image INT8
  intermediate feature maps INT8
  weight INT8
  bias INT32
  requant multiplier INT32
  fc2 logits INT32

CNN_ALU:
  현재 25개 activation
  현재 25개 weight
  acc_reg INT32
```

기존 RV32I load/store와 CNN_ALU load는 다릅니다.

```text
RV32I LB/LW:
  data memory -> register

RV32I SB/SW:
  register -> data memory

CNN LOAD_A/LOAD_W:
  register -> CNN_ALU act_buf/weight_buf

CNN GET_RES:
  CNN_ALU acc_reg -> register
```

## 2. Custom Instruction Helper

C로 표현하면 다음과 같은 helper가 필요합니다. 실제 구현은 inline assembly 또는 assembler macro로 작성합니다.

```c
uint32_t pack4(int8_t a, int8_t b, int8_t c, int8_t d) {
    return ((uint8_t)a) |
           ((uint32_t)(uint8_t)b << 8) |
           ((uint32_t)(uint8_t)c << 16) |
           ((uint32_t)(uint8_t)d << 24);
}

void cnn_load_w_pack4(uint32_t packed);
void cnn_load_a_pack4(uint32_t packed);
void cnn_start_mac(void);
void cnn_acc_mac(void);
void cnn_clear_acc(void);
void cnn_add_bias(int32_t bias);
void cnn_requant_relu(int32_t multiplier);
void cnn_start_pool(void);
int32_t cnn_get_res(void);
```

## 3. 25-slot Load Helper

CNN_ALU 내부 MAC은 32-slot padded 구조입니다. 소프트웨어는 매 chunk마다 25-slot까지 전송해야 합니다.

```c
void cnn_load_25_a(const int8_t v[25]) {
    for (int i = 0; i < 25; i += 4) {
        int8_t b0 = v[i];
        int8_t b1 = (i + 1 < 25) ? v[i + 1] : 0;
        int8_t b2 = (i + 2 < 25) ? v[i + 2] : 0;
        int8_t b3 = (i + 3 < 25) ? v[i + 3] : 0;
        cnn_load_a_pack4(pack4(b0, b1, b2, b3));
    }
}

void cnn_load_25_w(const int8_t v[25]) {
    for (int i = 0; i < 25; i += 4) {
        int8_t b0 = v[i];
        int8_t b1 = (i + 1 < 25) ? v[i + 1] : 0;
        int8_t b2 = (i + 2 < 25) ? v[i + 2] : 0;
        int8_t b3 = (i + 3 < 25) ? v[i + 3] : 0;
        cnn_load_w_pack4(pack4(b0, b1, b2, b3));
    }
}
```

## 4. Conv 5x5 Output 하나 계산

입력 channel이 1개인 conv1 output pixel:

```c
int8_t conv1_one_pixel(int oc, int row, int col) {
    int8_t act[25];
    int8_t weight[25];

    int idx = 0;
    for (int kr = 0; kr < 5; kr++) {
        for (int kc = 0; kc < 5; kc++) {
            act[idx] = input[row + kr][col + kc];
            weight[idx] = conv1_weight_int8[oc][0][kr][kc];
            idx++;
        }
    }

    cnn_clear_acc();
    cnn_load_25_a(act);
    cnn_load_25_w(weight);
    cnn_acc_mac();
    cnn_add_bias(conv1_bias_int32[oc]);
    cnn_requant_relu(conv1_requant_multiplier);

    return (int8_t)(cnn_get_res() & 0xff);
}
```

입력 channel이 여러 개인 conv2/conv3 output pixel:

```c
int8_t conv_multi_channel_one_pixel(...) {
    cnn_clear_acc();

    for (int ic = 0; ic < INPUT_CHANNELS; ic++) {
        extract_5x5_activation(act, ic, row, col);
        extract_5x5_weight(weight, oc, ic);

        cnn_load_25_a(act);
        cnn_load_25_w(weight);
        cnn_acc_mac();
    }

    cnn_add_bias(bias_int32[oc]);
    cnn_requant_relu(layer_requant_multiplier);

    return (int8_t)(cnn_get_res() & 0xff);
}
```

## 5. MaxPool 2x2 Output 하나 계산

```c
int8_t maxpool_one_pixel(int8_t p0, int8_t p1, int8_t p2, int8_t p3) {
    cnn_clear_acc();
    cnn_load_a_pack4(pack4(p0, p1, p2, p3));
    cnn_start_pool();
    return (int8_t)(cnn_get_res() & 0xff);
}
```

## 6. FC Output 하나 계산

FC1처럼 output을 다음 layer의 INT8 activation으로 넘기는 경우:

```c
int8_t fc1_one_neuron(int oc) {
    int8_t act[25];
    int8_t weight[25];

    cnn_clear_acc();

    for (int base = 0; base < 120; base += 25) {
        for (int i = 0; i < 25; i++) {
            int idx = base + i;
            act[i] = (idx < 120) ? c3_out[idx] : 0;
            weight[i] = (idx < 120) ? fc1_weight_int8[oc][idx] : 0;
        }

        cnn_load_25_a(act);
        cnn_load_25_w(weight);
        cnn_acc_mac();
    }

    cnn_add_bias(fc1_bias_int32[oc]);
    cnn_requant_relu(fc1_requant_multiplier);

    return (int8_t)(cnn_get_res() & 0xff);
}
```

FC2는 마지막 classification logit입니다. 현재 권장 방식은 requant 없이 INT32 logit을 그대로 비교하는 것입니다.

```c
int32_t fc2_one_logit(int digit) {
    int8_t act[25];
    int8_t weight[25];

    cnn_clear_acc();

    for (int base = 0; base < 84; base += 25) {
        for (int i = 0; i < 25; i++) {
            int idx = base + i;
            act[i] = (idx < 84) ? fc1_out[idx] : 0;
            weight[i] = (idx < 84) ? fc2_weight_int8[digit][idx] : 0;
        }

        cnn_load_25_a(act);
        cnn_load_25_w(weight);
        cnn_acc_mac();
    }

    cnn_add_bias(fc2_bias_int32[digit]);
    return cnn_get_res();
}
```

## 7. 전체 Inference 순서

```c
// input: int8_t input[32][32]

// C1: 1x32x32 -> 6x28x28
for (oc = 0; oc < 6; oc++)
  for (row = 0; row < 28; row++)
    for (col = 0; col < 28; col++)
      c1[oc][row][col] = conv1_one_pixel(oc, row, col);

// Pool1: 6x28x28 -> 6x14x14
for (ch = 0; ch < 6; ch++)
  for (row = 0; row < 14; row++)
    for (col = 0; col < 14; col++)
      p1[ch][row][col] = maxpool_one_pixel(...);

// C2: 6x14x14 -> 16x10x10
for (oc = 0; oc < 16; oc++)
  for (row = 0; row < 10; row++)
    for (col = 0; col < 10; col++)
      c2[oc][row][col] = conv2_one_pixel(oc, row, col);

// Pool2: 16x10x10 -> 16x5x5
for (ch = 0; ch < 16; ch++)
  for (row = 0; row < 5; row++)
    for (col = 0; col < 5; col++)
      p2[ch][row][col] = maxpool_one_pixel(...);

// C3: 16x5x5 -> 120
for (oc = 0; oc < 120; oc++)
  c3[oc] = conv3_one_pixel(oc);

// FC1: 120 -> 84
for (oc = 0; oc < 84; oc++)
  fc1[oc] = fc1_one_neuron(oc);

// FC2: 84 -> 10 logits
for (digit = 0; digit < 10; digit++)
  logits[digit] = fc2_one_logit(digit);

pred = argmax(logits);
```

## 8. RV32I 통합 전 작은 테스트 순서

전체 LeNet을 바로 올리면 디버깅이 어렵습니다. 다음 순서로 검증하는 것을 권장합니다.

```text
1. CLEAR_ACC + ADD_BIAS + GET_RES
2. LOAD_A/W + ACC_MAC
3. REQUANT_RELU
4. START_POOL
5. FC 한 뉴런
6. Conv1 한 output pixel
7. Conv1 전체 feature map
8. 0~9 샘플 전체 inference
```

## 9. 참고 C++ Golden Driver

현재 PC/HLS C simulation에서 검증된 전체 inference driver:

```text
FPGA_proj/tb_lenet_int8_cnn_alu.cpp
```

검증 결과:

```text
0_to_9_sample_accuracy=10/10
CSim done with 0 errors
```
