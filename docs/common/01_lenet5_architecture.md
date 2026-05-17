# LeNet-5 네트워크 아키텍처 상세 분석

## 1. 네트워크 구조

### 1.1 원본 LeNet-5 vs 수정 버전

원본 LeNet-5 (1998, LeCun)는 32×32 입력을 사용하지만, MNIST는 28×28이므로 수정 버전을 사용한다.

```
[Input]   28×28×1     (784 pixels, grayscale)
   ↓
[C1]      Conv2D      kernel=5×5, filters=6,  stride=1, padding=valid
          Output:     24×24×6
   ↓
[ReLU]    Activation  (원본은 tanh, 우리는 ReLU 사용)
   ↓
[S2]      MaxPool2D   kernel=2×2, stride=2    (원본은 AvgPool)
          Output:     12×12×6
   ↓
[C3]      Conv2D      kernel=5×5, filters=16, stride=1, padding=valid
          Output:     8×8×16
   ↓
[ReLU]    Activation
   ↓
[S4]      MaxPool2D   kernel=2×2, stride=2
          Output:     4×4×16
   ↓
[C5]      Conv2D      kernel=4×4, filters=120, stride=1, padding=valid
          (4×4 입력에 4×4 커널 → 사실상 FC와 동일)
          Output:     1×1×120
   ↓
[ReLU]    Activation
   ↓
[F6]      FC          120 → 84
   ↓
[ReLU]    Activation
   ↓
[Output]  FC          84 → 10
   ↓
[argmax]  Classification result (0~9)
```

> **참고**: 28×28 입력 + valid padding일 때 C5는 4×4 커널을 사용해야 출력이 1×1이 됨.
> 또는 5×5 커널을 유지하려면 C1에 padding=same을 사용하여 28×28을 유지.

### 1.2 채택할 구조 (수정 LeNet-5)

패딩 없이 구현의 단순함을 위해 아래 구조를 사용:

| 레이어 | 타입 | 설정 | 입력 크기 | 출력 크기 |
|--------|------|------|-----------|-----------|
| C1 | Conv2D | 5×5, 6 filters, valid | 28×28×1 | 24×24×6 |
| S2 | MaxPool2D | 2×2, stride 2 | 24×24×6 | 12×12×6 |
| C3 | Conv2D | 5×5, 16 filters, valid | 12×12×6 | 8×8×16 |
| S4 | MaxPool2D | 2×2, stride 2 | 8×8×16 | 4×4×16 |
| C5 | FC | 256→120 | 256 (=4×4×16) | 120 |
| F6 | FC | 120→84 | 120 | 84 |
| OUT | FC | 84→10 | 84 | 10 |

> C5를 FC로 바꾸면 flatten 후 행렬곱으로 처리 가능 → 구현이 단순해짐

---

## 2. 레이어별 상세 연산

### 2.1 C1: Convolution Layer 1

```
Input:  28×28×1 (784 values)
Weight: 6 × (5×5×1) = 6 × 25 = 150 weights + 6 biases = 156 params
Output: 24×24×6 = 3,456 values

연산 (output pixel 하나당):
  out[oy][ox][oc] = Σ(ky=0..4) Σ(kx=0..4) input[oy+ky][ox+kx] × weight[oc][ky][kx] + bias[oc]

MAC per output pixel: 25
Total MAC: 24 × 24 × 6 × 25 = 86,400
```

**커스텀 명령어 적용**:
- 5×5 = 25 MAC → MAC4를 6번 + 1 단독 MAC = 7 커스텀 명령어 (vs 50+ 기존 명령어)
- 또는 패딩하여 28 MAC (7 × MAC4)

### 2.2 S2: Max Pooling Layer 2

```
Input:  24×24×6
Output: 12×12×6 = 864 values

연산: 2×2 윈도우 내 최대값 선택
  out[oy][ox][c] = max(in[2oy][2ox][c], in[2oy][2ox+1][c],
                       in[2oy+1][2ox][c], in[2oy+1][2ox+1][c])

비교 횟수: 12 × 12 × 6 × 3 = 2,592 comparisons
```

**커스텀 명령어 적용**:
- MAXPOOL2: 4개 값을 한 번에 비교 → 비교 1회로 해결

### 2.3 C3: Convolution Layer 3

```
Input:  12×12×6
Weight: 16 × (5×5×6) = 16 × 150 = 2,400 weights + 16 biases = 2,416 params
Output: 8×8×16 = 1,024 values

MAC per output pixel: 5 × 5 × 6 = 150
Total MAC: 8 × 8 × 16 × 150 = 153,600
```

**커스텀 명령어 적용**:
- 150 MAC → MAC4 37번 + 2 단독 = ~38 커스텀 명령어 per output pixel

### 2.4 S4: Max Pooling Layer 4

```
Input:  8×8×16
Output: 4×4×16 = 256 values
비교 횟수: 4 × 4 × 16 × 3 = 768
```

### 2.5 C5 (FC): Fully Connected Layer

```
Input:  256 (flattened 4×4×16)
Weight: 120 × 256 = 30,720 weights + 120 biases = 30,840 params
Output: 120 values

MAC per output: 256
Total MAC: 120 × 256 = 30,720
```

**커스텀 명령어 적용**:
- 256 MAC → MAC4 64번 per output neuron

### 2.6 F6: Fully Connected Layer

```
Input:  120
Weight: 84 × 120 = 10,080 weights + 84 biases = 10,164 params
Output: 84 values

MAC per output: 120
Total MAC: 84 × 120 = 10,080
```

### 2.7 Output: Final FC Layer

```
Input:  84
Weight: 10 × 84 = 840 weights + 10 biases = 850 params
Output: 10 values

MAC per output: 84
Total MAC: 10 × 84 = 840
```

---

## 3. 연산량 요약 및 가속 효과 예측

### 3.1 총 연산량

| 레이어 | MAC 수 | 파라미터 수 | 비중(%) |
|--------|--------|------------|---------|
| C1 | 86,400 | 156 | 28.9% |
| C3 | 153,600 | 2,416 | 51.4% |
| C5 | 30,720 | 30,840 | 10.3% |
| F6 | 10,080 | 10,164 | 3.4% |
| OUT | 840 | 850 | 0.3% |
| Pool(S2+S4) | ~3,360 comp | 0 | 1.1% |
| ReLU | ~5,544 | 0 | 1.9% |
| **총합** | **~299K MAC** | **~44.4K** | **100%** |

### 3.2 소프트웨어 only (RV32I 싱글 사이클) 추론 사이클 예측

순수 RV32I 싱글 사이클로 1 MAC 연산 시 (CPI=1):
```
LW   weight      # 1 cycle
LW   input       # 1 cycle
MUL  (없음!)     # RV32I에는 MUL 없음 → 소프트웨어 곱셈 루틴 필요
ADD  accumulate  # 1 cycle
```

> **RV32I에는 MUL 명령어가 없다!** (M 확장 필요)
> 소프트웨어 곱셈: INT8×INT8 = ~15-20 instructions (shift-and-add)
> 싱글 사이클에서는 CPI=1이므로 명령어 수 = 사이클 수

**1 MAC ≈ 22~25 cycles** (load + SW multiply + accumulate)
**총 추론**: 299K × 25 = **~7.5M cycles**
@50MHz (싱글 사이클 예상 클럭) → ~150ms per image

### 3.3 커스텀 명령어 사용 시 추론 사이클 예측

MAC4 사용 시 (싱글 사이클, CPI=1):
```
LW   weight_packed  # 1 cycle (4 weights at once)
LW   input_packed   # 1 cycle (4 inputs at once)
MAC4 tmp, w, i      # 1 cycle (4 MAC in parallel)
ADD  acc, acc, tmp  # 1 cycle (누적)
```

**4 MAC ≈ 4 cycles** → **1 MAC ≈ 1 cycle**
**총 추론**: 299K / 4 × 4 + 오버헤드(루프,주소계산) ≈ **~400K cycles**
@50MHz → ~8ms per image

### 3.4 가속비 (Speedup)

| 항목 | SW Only | Custom ISA | 가속비 |
|------|---------|------------|--------|
| 사이클 | ~7.5M | ~400K | **~18.8×** |
| 시간@50MHz | ~150ms | ~8ms | **~18.8×** |

> 싱글 사이클의 CPI=1 덕분에 커스텀 명령어의 효과가 파이프라인보다 더 직접적으로 나타남.

---

## 4. 메모리 요구사항

### 4.1 가중치 저장

| 레이어 | 파라미터 수 | INT8 크기 | INT32 Bias |
|--------|------------|-----------|------------|
| C1 | 150 + 6 | 150B | 24B |
| C3 | 2,400 + 16 | 2,400B | 64B |
| C5 | 30,720 + 120 | 30,720B | 480B |
| F6 | 10,080 + 84 | 10,080B | 336B |
| OUT | 840 + 10 | 840B | 40B |
| **합계** | | **~44.2KB** | **~944B** |

### 4.2 활성화 버퍼 (Double Buffering)

최대 활성화 크기 = C1 출력: 24×24×6 = 3,456 bytes
Double buffer: ~7KB

### 4.3 총 BRAM 요구사항

| 용도 | 크기 |
|------|------|
| 프로그램 코드 | ~8-16KB |
| 가중치 | ~45KB |
| 활성화 버퍼 ×2 | ~7KB |
| 스택 | ~4KB |
| 입력 이미지 | 784B |
| **합계** | **~72KB** |

→ Zynq-7020의 BRAM (630KB 가용) 에 충분히 수용 가능

---

## 5. PyTorch 모델 학습 계획

### 5.1 학습 코드 구조

```python
import torch
import torch.nn as nn

class LeNet5_MNIST(nn.Module):
    def __init__(self):
        super().__init__()
        self.conv1 = nn.Conv2d(1, 6, 5)       # C1
        self.pool  = nn.MaxPool2d(2, 2)         # S2, S4
        self.conv2 = nn.Conv2d(6, 16, 5)       # C3
        self.fc1   = nn.Linear(4*4*16, 120)    # C5
        self.fc2   = nn.Linear(120, 84)        # F6
        self.fc3   = nn.Linear(84, 10)         # Output
        self.relu  = nn.ReLU()
    
    def forward(self, x):
        x = self.relu(self.conv1(x))   # 28→24
        x = self.pool(x)               # 24→12
        x = self.relu(self.conv2(x))   # 12→8
        x = self.pool(x)               # 8→4
        x = x.view(-1, 4*4*16)         # Flatten
        x = self.relu(self.fc1(x))
        x = self.relu(self.fc2(x))
        x = self.fc3(x)
        return x
```

### 5.2 양자화 워크플로우

1. **FP32 학습** → MNIST test accuracy ≥ 99%
2. **QAT (Quantization-Aware Training)**:
   ```python
   model.qconfig = torch.ao.quantization.get_default_qat_qconfig('fbgemm')
   torch.ao.quantization.prepare_qat(model, inplace=True)
   # Fine-tune for a few epochs
   quantized_model = torch.ao.quantization.convert(model)
   ```
3. **INT8 가중치/스케일 추출** → C 헤더 파일 생성
4. **정확도 검증**: INT8 모델 MNIST test accuracy ≥ 98%

### 5.3 가중치 추출 포맷

```c
// weights.h
// C1 weights: 6 filters × 5 × 5 × 1 = 150 values (INT8)
const int8_t c1_weights[6][5][5] = { ... };
const int32_t c1_bias[6] = { ... };
const uint8_t c1_shift = 7;  // rescale shift amount

// C3 weights: 16 filters × 5 × 5 × 6 = 2400 values
const int8_t c3_weights[16][6][5][5] = { ... };
// ... etc
```
