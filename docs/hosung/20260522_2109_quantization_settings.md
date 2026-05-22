# LeNet-5 INT8 양자화 설정 (현재)

## 범위 및 근거
- 기준 파일: sw/train_and_quantize.py
- 내보낸 파라미터: sw/output/weights.h (export_for_hw 생성)
- 이 문서는 weights.h의 현재 출력값을 반영합니다.

## 양자화 방식
- 프레임워크: PyTorch 정적 양자화(PTQ)
- Activation: quint8, per-tensor affine
- Weight: qint8, per-tensor symmetric
- Calibration: MNIST 약 2500장 (10 batches)

## 입력 양자화
- 입력 scale: 1/255 = 0.00392157
- 입력 zero_point: 0
- 입력 픽셀은 uint8 (0..255)이며 QUINT8 + zero_point 0과 일치합니다.

## 데이터 타입 및 산술 가정
- Activation (rs1): uint8
- Weight (rs2): int8
- Accumulator: int32
- Bias: int32
- MAC4는 unsigned(activation) x signed(weight)
- RESCALE은 rounding + arithmetic shift + [0, 255] clamp 사용

## Bias 양자화 및 리스케일 수식
- Bias scale: $S_{bias} = S_{in} \cdot S_w$
- Bias int32: $b_{int32} = round(b_{fp32} / S_{bias})$
- Rescale multiplier: $M = \frac{S_{in} \cdot S_w}{S_{out}}$
- RTL 리스케일(현재):
  - shift = round(-log2(M)) for 0 < M < 1
  - output = clamp((acc + (1 << (shift - 1))) >> shift, 0, 255)
- 참고: M은 weights.h에 기록되지만, 현재 RTL은 shift만 사용합니다.

## 레이어별 출력 파라미터 (weights.h 기준)
| Layer | Shape | Weight scale | Shift | M |
|---|---|---|---|---|
| conv1 | (6, 1, 5, 5) | 0.003214 | 10 | 0.000741 |
| conv2 | (16, 6, 5, 5) | 0.003048 | 10 | 0.000893 |
| fc1 | (120, 256) | 0.003096 | 9 | 0.001529 |
| fc2 | (84, 120) | 0.003384 | 9 | 0.002616 |
| fc3 | (10, 84) | 0.002572 | 9 | 0.002228 |

## 스케일 전파 (버그 수정 반영)
- 각 레이어는 직전 레이어의 출력 scale을 입력 scale로 사용합니다:
  - conv1: model_q.quant.scale
  - conv2: model_q.conv1.scale
  - fc1: model_q.conv2.scale
  - fc2: model_q.fc1.scale
  - fc3: model_q.fc2.scale

## 생성 파일
- sw/output/weights.h
- sw/output/weights.hex
- sw/output/weights_map.txt
- sw/output/test_images.hex
- sw/output/test_labels.txt
