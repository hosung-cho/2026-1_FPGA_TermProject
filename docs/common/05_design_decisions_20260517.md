# 설계 결정 사항 (2026-05-17)

## 1. 베이스 코어 선택: 싱글 사이클

### 결정
**싱글 사이클 코어를 베이스로 사용한다.**

### 근거

#### CNN 추론 워크로드 분석
CNN 추론의 핵심 내부 루프:
```asm
loop:
    LW     weight
    LW     input
    MAC4   acc, w, i
    ADD    acc, acc, tmp
    addi   ptr, ptr, 4
    bne    cnt, x0, loop
```

파이프라인에서 발생하는 패널티:
- **Load-use stall**: `LW → MAC4` 의존성으로 매 반복마다 1~2 cycle stall
- **Branch flush**: 루프 끝 `bne`에서 3 cycle flush (MEM단 분기 해소)
- 예상 CPI: ~1.5~1.8

싱글 사이클:
- CPI = **항상 1.0**
- stall/flush 없음
- 클럭은 낮지만 실효 성능 차이 미미

#### 구현 난이도
| 항목 | 싱글 사이클 | 파이프라인 |
|------|------------|-----------|
| 디코더 수정 | 간단 (case 추가) | 동일 |
| CFU 통합 | ALU 옆에 MUX 추가 | EX 스테이지 + 파이프라인 레지스터 전파 |
| 포워딩 | 불필요 | 기존 포워딩으로 커버 가능하나 검증 복잡 |
| 검증 복잡도 | 낮음 | 높음 (해저드 케이스 다수) |
| 디버깅 | 사이클 단위로 추적 용이 | 파이프라인 상태 추적 필요 |

#### 프로젝트 전략
1. **Phase 1**: 싱글 사이클 + CFU → 기능 검증 완료
2. **Phase 2** (시간 여유 시): 파이프라인 + CFU → 성능 비교
3. **보고서**: 두 버전 성능 비교 시 학술적 가치 극대화

---

## 2. 데이터 표현: INT8 정수 양자화 (Integer Quantization)

### 결정
**INT8 정수 양자화를 사용한다.** (고정소수점이 아님)

### 용어 정리

| 용어 | 정의 | 이 프로젝트 해당 여부 |
|------|------|---------------------|
| 정수 (Integer) | 소수점 없는 숫자 (예: INT8 = -128~127) | ✅ 사용 |
| 고정소수점 (Fixed-point) | 암묵적 소수점 위치 고정 (예: Q7 = -1.0~0.992) | ❌ 미사용 |
| 부동소수점 (Floating-point) | IEEE 754, FPU 필요 | ❌ 미사용 |

### 양자화 원리

```
실수값 (real_value) = scale × (정수값 - zero_point)

역양자화(dequantize): real = scale × int8_val    (symmetric, zero_point=0)
양자화(quantize):     int8 = clamp(round(real / scale), -128, 127)
```

### 연산 흐름 (전 과정 정수 연산)

```
[INT8 input] × [INT8 weight]  →  [INT16 partial product]
                                        ↓ 누적
                                  [INT32 accumulator]
                                        ↓ + INT32 bias
                                  [INT32 biased sum]
                                        ↓ × M (정수), >> shift
                                  [INT32 rescaled]
                                        ↓ clamp(0, 255)
                                  [UINT8 output activation]
```

여기서 `M`과 `shift`는 입출력 scale factor의 비율을 정수 곱셈+shift로 근사한 것:
```
M_real = (S_input × S_weight) / S_output
M_real ≈ M_int × 2^(-shift)
```

### HW 구현 관점
- 곱셈기: 8-bit × 8-bit → 16-bit (정수 곱셈기)
- 누적기: 32-bit 정수 덧셈기
- Rescale: 32-bit 정수 shift + clamp
- **FPU 불필요** → RV32I에 최적

---

## 3. 구현 방식: RTL (Verilog)

### 결정
**RTL(Verilog)로 직접 구현한다.** (HLS 미사용)

### 근거

#### CFU 로직의 단순성
```
MAC4:     곱셈기 4개 + 덧셈기 3개 (조합 로직)
ReLU:     MUX 1개
MaxPool2: 비교기 3개
CLRACC:   상수 0 출력
Rescale:  Barrel shifter + 비교기 2개
```
→ 전체 CFU가 **Verilog 50줄 이내**로 구현 가능

#### HLS의 오버헤드
HLS를 사용하면:
1. AXI 인터페이스 래핑 필요 (ap_ctrl, AXI-Lite/Stream)
2. 불필요한 핸드셰이크 로직 생성
3. 코어 내부 파이프라인에 직접 삽입 불가 → 외부 IP로 연결해야 함
4. 레이턴시 예측 어려움

#### 학술적 가치
- FPGA 수업 텀프로젝트: **직접 RTL 설계**가 평가에 유리
- HLS 사용 시 "도구에 의존" 인상을 줄 수 있음
- ISA 확장의 핵심은 디코더↔데이터패스 통합 → RTL만 가능

#### HLS가 적합했을 경우 (참고)
만약 **외부 오프로딩 가속기**를 만들었다면:
- 복잡한 타일링 FSM, DMA 제어
- AXI Master 인터페이스
- 수백 줄의 제어 로직
→ 이 경우 HLS가 생산성 면에서 유리했을 것

하지만 교수님 피드백에 따라 **코어 내부 ISA 확장**을 선택했으므로 RTL이 자연스러운 선택.
