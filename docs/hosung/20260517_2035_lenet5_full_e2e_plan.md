# LeNet-5 풀 네트워크 RTL E2E 검증 구현 계획서

본 계획서는 **5단계(풀 네트워크 LeNet-5 모델 전체 E2E 검증)**를 하드웨어 수준에서 정확하게 수행하기 위한 설계 및 개발 방향을 제시합니다.

---

## 1. 검증 목표 및 범위
- **검증 대상**: LeNet-5 전체 레이어 통합 추론
  - `Conv1` → `Pool1` → `Conv2` → `Pool2` → `FC1` → `FC2` → `FC3`
- **구동 환경**: 커스텀 CFU 명령어(`MAC4`, `RESCALE`, `RELU`, `MAXPOOL2`)가 활성화된 싱글 사이클 RV32I CPU 코어
- **성공 판정 기준**: 테스트 이미지 0번(실제 Label: `7`)을 입력받아 최종 클래스별 점수를 계산하고, 최댓값 인덱스(Argmax)가 정확히 `7`을 나타내어 BRAM 첫 워드(`dmem[0]`)에 `0x12345678`이 성공적으로 저장되는가 여부

---

## 2. 하드웨어 메모리 확장 설계 (32KB → 64KB RAM)

### 2.1 확장 필요성
- LeNet-5 전체 가중치(Weights) 및 편향(Biases) 데이터 크기: **약 45KB**
- 기존 32KB RAM 스페이스에는 모든 데이터와 연산 버퍼가 물리적으로 담길 수 없습니다.
- 따라서, 시뮬레이션용 데이터 메모리(Data BRAM) 스페이스를 **64KB (16,384 words)**로 확장하여 설계합니다.

### 2.2 메모리 맵 및 어드레스 디코딩 수정
- **RAM 시작 주소**: `0x00008000`
- **RAM 끝 주소**: `0x00017FFF` (64KB 공간)
- **Stack Pointer (`sp`) 초기치**: `0x00018000` (RAM의 물리적 끝점)
- **RTL 어드레스 디코더 수정 (`lenet5_e2e_tb.v`)**:
  - 기존 32KB RAM 인덱스 width: `13` bits (`MemAddr[15:2] - 14'h2000`)
  - 확장 64KB RAM 인덱스 width: **`14` bits** (`MemAddr[15:2] - 14'h2000`)
  ```verilog
  reg [31:0] dmem [0:16383]; // 64KB RAM
  wire [13:0] daddr = MemAddr[15:2] - 14'h2000;
  ```

---

## 3. 소프트웨어 알고리즘 설계 및 가중치 패딩 기법

하드웨어 CFU 가속기(`cfu_mac4`)는 4개의 `int8_t`/`uint8_t` 데이터를 1개의 32비트 워드로 묶어서 입력받습니다. 따라서 4비트 정렬이 맞지 않는 레이어는 복사/패딩 처리가 필요합니다.

### 3.1 레이어별 패딩(Padding) 및 정렬 방식
1. **`conv1`**: 커널 크기 $5 \times 5 = 25$ 바이트. 
   - $28$ 바이트로 패딩 (25개 가중치 + 3개 Zero-padding).
2. **`conv2`**: 입력 채널 $6 \times$ 커널 크기 $5 \times 5 = 150$ 바이트.
   - $152$ 바이트로 패딩 (150개 가중치 + 2개 Zero-padding).
3. **`fc1`, `fc2`, `fc3`**: 각각 입력 크기가 $256, 120, 84$ 바이트로 **이미 4의 배수**입니다.
   - **패딩이 필요 없으며**, 원본 가중치 배열을 `cfu_mac4`로 즉시 고속 루프 연산 가능합니다.

### 3.2 런타임 제로 패딩 (Runtime Padding) 기법 도입
C 코드 컴파일 크기를 간결하게 유지하기 위해, `weights.h` 내의 비정렬 원본 상수 배열을 런타임 시작 시 정렬 버퍼(`conv1_w_padded`, `conv2_w_padded`)로 복사 및 제로 패딩 처리하는 초기화 함수(`prepare_weights`)를 구동합니다.
*이 작업은 최초 구동 시 단 1회만 실행되며 전체 사이클 오버헤드는 0.3% 미만입니다.*

---

## 4. 상세 제안 변경 사항

### 4.1 시뮬레이션 통합 테스트 환경 구축
- **새 경로**: `testbench/4_full_e2e/`
- **신규 파일**:
  - `testbench/4_full_e2e/lenet5.c`: C 언어 LeNet-5 전체 레이어 CFU 통합 추론 프로그램
  - `testbench/4_full_e2e/startup.S`: 64KB RAM 스택 포인터(`sp = 0x00018000`) 초기화 코드가 반영된 스타트업 파일
  - `testbench/4_full_e2e/link.ld`: 64KB ram 영역을 정의하는 링커 스크립트
  - `testbench/4_full_e2e/lenet5_e2e_tb.v`: 64KB DMEM 크기 및 시뮬레이션 타임아웃(최대 5,000,000 사이클)이 반영된 통합 테스트벤치
  - `testbench/4_full_e2e/sim/run.sh` & `run_sim.tcl`: Vivado 원터치 시뮬레이션 실행 환경 스크립트

---

## 5. 검증 계획

### 5.1 크로스 컴파일 및 기계어 추출
- `testbench/4_full_e2e/` 경로에 `./compile.sh`를 작성하여 `lenet5.c` 및 `startup.S`를 빌드하고 `imem.hex`, `dmem.hex`를 자동 분리 추출합니다.

### 5.2 시뮬레이션 수행
- `testbench/4_full_e2e/sim/`으로 이동하여 `./run.sh`를 실행합니다.
- 시뮬레이션 중 CPU가 Halt에 정상 도달하고, BRAM 첫 번째 워드(`dmem[0]`) 값이 성공 코드를 완벽하게 복사해 내는지 확인합니다.
  - 출력: `Status Value (dmem[0]): 0x12345678`
  - 메시지: `*** LENET5 FULL E2E VERIFICATION PASSED ***`
