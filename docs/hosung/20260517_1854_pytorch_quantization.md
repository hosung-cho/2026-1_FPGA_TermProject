# LeNet-5 학습 + INT8 양자화 + HEX 추출 완료

## 작업 일시
2026-05-17 18:54 ~ 19:06

## 작업 내용

### 1. 환경 설정

- Python 3.12 + venv 생성 (`.venv/`)
- PyTorch 2.12.0 (CPU) + torchvision 설치
- `.gitignore`에 `.venv` 추가

### 2. 학습 결과 (FP32)

| Epoch | Loss | Train Acc | Test Acc |
|-------|------|-----------|----------|
| 1/5 | 0.3200 | 90.61% | 97.10% |
| 2/5 | 0.0877 | 97.42% | 98.09% |
| 3/5 | 0.0620 | 98.12% | 98.72% |
| 4/5 | 0.0492 | 98.48% | 98.69% |
| 5/5 | 0.0410 | 98.68% | **98.77%** |

### 3. INT8 양자화 결과

**방식**: Per-Layer Symmetric INT8 Quantization (수동 구현)

| 레이어 | Shape | w_scale | shift | w_range |
|--------|-------|---------|-------|---------|
| conv1 | (6,1,5,5) | 0.003792 | 9 | [-127, 93] |
| conv2 | (16,6,5,5) | 0.002925 | 12 | [-127, 94] |
| fc1 | (120,256) | 0.002481 | 12 | [-127, 102] |
| fc2 | (84,120) | 0.002039 | 11 | [-127, 125] |
| fc3 | (10,84) | 0.002370 | 11 | [-127, 74] |

### 4. 정확도 비교

| 모델 | Test Accuracy | 차이 |
|------|--------------|------|
| FP32 | 98.77% | - |
| INT8 (dequantized) | **98.76%** | **-0.01%** |

→ 양자화 정확도 손실이 거의 없음! (MNIST + LeNet-5는 쉬운 문제라 PTQ만으로 충분)

### 5. 생성된 파일

| 파일 | 위치 | 설명 |
|------|------|------|
| `lenet5_fp32.pth` | `sw/output/` | FP32 학습 모델 |
| `weights.h` | `sw/output/` | C 헤더 파일 (INT8 가중치 + INT32 바이어스 + shift) |
| `weights.hex` | `sw/output/` | BRAM 로드용 HEX (45,136 bytes ≈ 44KB) |
| `weights_map.txt` | `sw/output/` | 메모리 맵 (레이어별 오프셋) |
| `test_images.hex` | `sw/output/` | MNIST 테스트 이미지 10장 (UINT8) |
| `test_labels.txt` | `sw/output/` | 정답 레이블 |

### 6. 양자화 방식 상세

```
FP32 가중치 → INT8 변환:
  scale = max(|w_fp32|) / 127
  w_int8 = round(w_fp32 / scale), clamp [-128, 127]

추론 시:
  accumulator = Σ(input_uint8 × weight_int8) + bias_int32
  output_uint8 = RESCALE(accumulator, shift)
               = clamp((accumulator + (1 << (shift-1))) >> shift, 0, 255)
```

### 7. 실행 방법

```bash
source .venv/bin/activate  # 또는 .venv/bin/python3 직접 사용
python sw/train_and_quantize.py
```

## 다음 단계

4단계: 추론 프로그램 작성 + E2E 시뮬레이션
- C/ASM으로 LeNet-5 추론 루틴 작성 (커스텀 명령어 활용)
- 크로스 컴파일 → HEX 변환
- 시뮬레이션에서 MNIST 이미지 추론 정확도 검증
