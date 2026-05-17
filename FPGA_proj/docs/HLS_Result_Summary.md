# HLS / INT8 LeNet 작업 결과 요약

이 문서는 ReLU + MaxPool LeNet-5용 INT8 CNN_ALU 개발, 학습, 양자화, 검증 결과를 정리합니다.

## 1. 목표

기존 float/tanh/average-pooling LeNet 구조를 FPGA 친화적인 형태로 변경했습니다.

변경된 구조:

```text
Input 1x32x32
  -> Conv1(1->6, 5x5) + ReLU
  -> MaxPool2d
  -> Conv2(6->16, 5x5) + ReLU
  -> MaxPool2d
  -> Conv3(16->120, 5x5) + ReLU
  -> FC1(120->84) + ReLU
  -> FC2(84->10 logits)
```

하드웨어 방향:

```text
INT8 activation
INT8 weight
INT32 accumulator
INT32 bias
INT32 -> INT8 requantization
```

## 2. 생성 파일

학습/양자화:

```text
train_lenet_relu_maxpool.py
lenet_relu_maxpool_float_10epoch.pth
export_lenet_int8.py
lenet_int8_params.h
lenet_int8_scales.txt
```

HLS / 테스트:

```text
cnn_alu.cpp
cnn_alu.h
tb_cnn_alu.cpp
tb_lenet_int8_cnn_alu.cpp
run_csim.tcl
run_csynth.tcl
run_lenet_csim.tcl
```

RTL 산출물:

```text
cnn_alu_hls_prj/solution1/syn/verilog/CNN_ALU_Top.v
cnn_alu_hls_prj/solution1/syn/verilog/CNN_ALU_Top_mac_mdEe.v
cnn_alu_hls_prj/solution1/syn/verilog/CNN_ALU_Top_mux_3bkb.v
cnn_alu_hls_prj/solution1/syn/verilog/CNN_ALU_Top_mux_8cud.v
```

## 3. 모델 학습 결과

기존 README baseline:

```text
기존 SW accuracy: 98.63% single precision fp
기존 HW accuracy: 98.63% single precision fp
```

새 ReLU + MaxPool 모델:

```text
epoch=1  test_acc=97.29%
epoch=2  test_acc=97.35%
epoch=3  test_acc=98.24%
epoch=4  test_acc=98.67%
epoch=5  test_acc=98.63%
epoch=6  test_acc=98.82%
epoch=7  test_acc=98.93%
epoch=8  test_acc=98.90%
epoch=9  test_acc=98.86%
epoch=10 test_acc=98.97%
```

최종 float checkpoint:

```text
lenet_relu_maxpool_float_10epoch.pth
test_acc = 98.97%
```

## 4. INT8 양자화 결과

양자화 방식:

```text
weight: per-layer symmetric INT8
bias: input_scale * weight_scale 기준 INT32
activation: calibration 기반 per-layer INT8 scale
requant: fixed-point multiplier + shift
```

Fake INT8 PyTorch 평가:

```text
float_test_acc      = 98.97%
fake_quant_test_acc = 98.98%
```

주요 scale:

```text
[activation_scales]
input=0.0078740157
relu1=0.0351401352
pool1=0.0351401352
relu2=0.0721680949
pool2=0.0721680949
relu3=0.1546027416
relu_fc1=0.1873535397
fc2=0.2262473069

[weight_scales]
conv1=0.0035218139
conv2=0.0039059665
conv3=0.0033975077
fc1=0.0030285589
fc2=0.0032701237
```

Requant multiplier:

```text
shift=20
conv1_multiplier=827
conv2_multiplier=1994
conv3_multiplier=1663
fc1_multiplier=2621
fc2_multiplier=2840
```

## 5. CNN_ALU 기능

현재 CNN_ALU opcode:

```text
0 CMD_LOAD_W_PACK4
1 CMD_LOAD_A_PACK4
2 CMD_START_MAC
3 CMD_GET_RES
4 CMD_START_POOL
5 CMD_CLEAR_ACC
6 CMD_ACC_MAC
7 CMD_APPLY_RELU
8 CMD_ADD_BIAS
9 CMD_REQUANT_RELU
```

핵심 datapath:

```text
LOAD_A/LOAD_W:
  rs1_data 32-bit에서 signed INT8 4개 unpack

MAC:
  32-slot padded dot product
  실제 5x5 유효값 25개 + padding 7개

ACC_MAC:
  multi-channel conv / FC chunk 누적

ADD_BIAS:
  signed INT32 bias add

REQUANT_RELU:
  acc_reg = clamp_relu(round(acc_reg * multiplier / 2^20))

GET_RES:
  acc_reg readback
```

## 6. C Simulation 검증

단품 CNN_ALU 테스트:

```text
테스트 파일: tb_cnn_alu.cpp
검증 항목:
  5x5 MAC
  negative INT8 MAC
  MAC -> Bias -> ReLU 순서
  2x2 MaxPool
  FC chunk accumulation
  Requant rounding
  Requant ReLU negative clamp
  Requant positive saturation

결과:
  CNN_ALU_Top C simulation passed
  CSim done with 0 errors
```

LeNet 전체 0~9 sample 테스트:

```text
테스트 파일: tb_lenet_int8_cnn_alu.cpp
결과:
  digit 0 -> pred 0
  digit 1 -> pred 1
  digit 2 -> pred 2
  digit 3 -> pred 3
  digit 4 -> pred 4
  digit 5 -> pred 5
  digit 6 -> pred 6
  digit 7 -> pred 7
  digit 8 -> pred 8
  digit 9 -> pred 9

  0_to_9_sample_accuracy=10/10
  CSim done with 0 errors
```

## 7. HLS Synthesis 결과

Target:

```text
Device: xc7z020clg484-1
Clock target: 10.00 ns
```

Timing:

```text
Estimated clock: 8.510 ns
```

Latency:

```text
Top latency: 1~11 cycles
MAC_LOOP latency: 8 cycles
MAC_LOOP II: 1
```

Resource estimate:

```text
BRAM_18K: 0
DSP48E: 8
FF: 1%
LUT: 2%
URAM: 0
```

주의:

```text
CMD_REQUANT_RELU의 32x32 multiply가 DSP를 일부 사용합니다.
리포트상 product_V 곱셈이 DSP 4개로 잡힙니다.
전체 DSP 사용량은 8개입니다.
```

## 8. 현재 완료 상태

```text
ReLU + MaxPool LeNet float 학습 완료
INT8 weight / INT32 bias export 완료
activation scale / requant multiplier 생성 완료
CNN_ALU CSim 통과
LeNet 전체 0~9 sample CSim 통과
HLS RTL synthesis 통과
Verilog RTL 생성 완료
```

## 9. 남은 작업

RV32I 통합 작업:

```text
1. RV32I decoder에서 custom opcode 인식
2. cnn_op[3:0] 생성
3. CNN_ALU wrapper 작성
4. ap_start/ap_done 기반 stall 제어
5. rd_data writeback 연결
6. data memory에 weight/bias/input 배치
7. RV32I firmware 작성
8. 단일 명령 -> conv1 pixel -> 0~9 sample 순서로 RTL 검증
```

개선 가능 작업:

```text
1. lenet_int8_params.h -> data memory .mem 변환
2. no_pragma 버전 최신화 및 성능 비교
3. C/RTL co-simulation 추가
4. 전체 MNIST 10000장 C++ driver 평가
```
