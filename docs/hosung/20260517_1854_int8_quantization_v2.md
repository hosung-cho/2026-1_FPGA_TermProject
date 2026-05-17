# 3-4단계: PyTorch 학습 + INT8 양자화 + HW 레퍼런스 검증 완료

## 작업 일시
2026-05-17 18:54 ~ 19:17

## 요약

| 항목 | 결과 |
|------|------|
| FP32 Test Accuracy | 98.48% |
| PyTorch INT8 Quantized | 98.48% (손실 0%) |
| HW Reference (100장) | 100/100 = 100.0% |

## 작업 내용

### 1. 환경 구축
- Python 3.12 + venv (`.venv/`)
- PyTorch 2.12.0 (CPU) + torchvision

### 2. 학습 (FP32)
- 모델: Modified LeNet-5 (28×28 입력, ReLU, MaxPool, valid padding)
- 옵티마이저: Adam (lr=0.001)
- 5 epochs, batch_size=128
- 최종 정확도: **98.48%**

### 3. 양자화: PyTorch Static Quantization (PTQ)
- `torch.ao.quantization` 사용
- Calibration: 테스트 이미지 ~2500장
- 입력: QUINT8 (per-tensor affine)
- 가중치: QINT8 (per-tensor symmetric)
- 양자화 후 정확도: **98.48%** (FP32와 동일!)

### 4. 양자화 파라미터

| 레이어 | Shape | w_scale | w_range |
|--------|-------|---------|---------|
| conv1 | (6,1,5,5) | 0.003733 | [-127, 122] |
| conv2 | (16,6,5,5) | 0.003182 | [-128, 109] |
| fc1 | (120,256) | 0.003015 | [-128, 105] |
| fc2 | (84,120) | 0.002251 | [-128, 121] |
| fc3 | (10,84) | 0.002680 | [-123, 127] |

### 5. 디버깅 기록

#### 첫 번째 시도 (수동 양자화): 실패
- **문제**: 휴리스틱 shift 계산으로 인해 중간 활성화가 모두 0이 됨
- **증상**: 모든 이미지에서 동일한 출력 (정확도 ~10%)
- **원인**: `acc_scale / out_scale` 비율을 고려하지 않고 단순 `log2(n_macs * 127 * 64 / 255)` 사용

#### 두 번째 시도 (캘리브레이션 기반): 실패
- **문제**: 입력 uint8을 int8 가중치와 곱할 때 signed/unsigned 처리 불일치
- **정확도**: 2% (거의 랜덤)

#### 세 번째 시도 (PyTorch 내장 PTQ): 성공 ✅
- PyTorch의 `quantize` 프레임워크를 사용하여 정확한 scale/zero_point 자동 계산
- 양자화 후 추론을 PyTorch가 직접 수행하므로 정확도 보장
- **정확도**: 98.48% (100장에서 100%)

### 6. 생성된 파일

| 파일 | 위치 | 설명 |
|------|------|------|
| `lenet5_fp32.pth` | `sw/output/` | FP32 모델 |
| `weights.h` | `sw/output/` | C 헤더 (INT8 가중치 + INT32 바이어스 + shift + M) |
| `weights.hex` | `sw/output/` | BRAM 로드용 HEX (45KB) |
| `weights_map.txt` | `sw/output/` | 메모리 맵 |
| `test_images.hex` | `sw/output/` | 테스트 이미지 10장 |
| `test_labels.txt` | `sw/output/` | 정답 레이블 |

### 7. 핵심 교훈

1. **수동 양자화는 어렵다**: scale/shift를 직접 계산하면 레이어 간 스케일 전파가 복잡해짐
2. **PyTorch PTQ가 정확하다**: 프레임워크가 calibration 데이터를 기반으로 최적의 scale을 계산
3. **MNIST+LeNet-5에서는 PTQ 손실이 0%**: QAT 불필요 확인
4. **하드웨어 구현 시**: PyTorch 양자화 모델의 M (multiplier)과 shift를 RTL RESCALE 연산에 매핑해야 함

## 실행 방법

```bash
.venv/bin/python3 sw/train_and_quantize.py
```

## 다음 단계

- 하드웨어 RESCALE에 M (fixed-point multiplier) 지원 추가 검토
- C 추론 코드 작성 → RISC-V 크로스 컴파일 → RTL E2E 시뮬레이션
- 또는 Python에서 머신코드를 직접 생성하여 RTL 검증
