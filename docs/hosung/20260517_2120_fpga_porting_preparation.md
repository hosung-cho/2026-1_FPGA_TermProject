# FPGA 포팅 준비 및 Vitis 호스트 프로그램 설계 보고서

- **작성일시**: 2026년 5월 17일 21:20
- **문서 목적**: RTL E2E 최종 검증 통과 후, 실제 FPGA 보드(Zynq SoC 기반) 포팅을 위한 하드웨어 통합 구조 설계 및 호스트 소프트웨어 자동 생성 내용 정리.
- **포팅 대상 코어**: RV32I 싱글 사이클 + CNN CFU 가속 명령어 통합 코어

---

## 1. FPGA SoC 시스템 통합 설계 (Vivado Block Design)

실제 FPGA 보드 상에서 Zynq PS(Processor System)가 가중치 및 기계어를 주입하고, RISC-V 코어가 이를 실행하여 결과를 다시 Zynq가 읽어갈 수 있도록 **Dual-Port BRAM**을 활용한 SoC 구조를 설계합니다.

### 1.1 하드웨어 주소 맵핑 (Zynq PS 관점)
*   **Instruction BRAM (INST BRAM)**: `0xA0000000` (axi_bram_ctrl_0)
*   **Data BRAM (DATA BRAM)**: `0xA0010000` (axi_bram_ctrl_1)

### 1.2 연결 구조 (Dual-Port 연결)
*   **BRAM Port A**: Zynq PS의 AXI BRAM Controller와 연결되어 호스트 프로그램이 `imem`과 `dmem`을 직접 읽고 씁니다.
*   **BRAM Port B**: 우리 커스텀 RISC-V 코어([RV32I_System](file:///home/hosung/Ho/2026-1_FPGA_Design/2026-1_FPGA_TermProject/src/rtl/RV32I_System.v))의 외부 메모리 인터페이스 포트와 연결되어 CPU의 Fetch 및 Load/Store 연산을 수행합니다.
*   **Reset 제어**: Zynq AXI GPIO 또는 VIO(Virtual Input/Output)의 출력 핀을 `RV32I_System`의 `reset` 핀과 연결하여 소프트웨어적으로 CPU 구동 타이밍을 제어합니다.

---

## 2. Vitis 호스트 프로그램 자동 생성

RTL E2E 테스트벤치에서 컴파일이 검증된 최신 기계어 ROM 파일(`imem.hex`)과 올바르게 양자화된 RAM 데이터 파일(`dmem.hex`)을 C언어 배열로 변환하고, Zynq 상에서 구동할 수 있는 완벽한 [vitis_lenet5.c](file:///home/hosung/Ho/2026-1_FPGA_Design/2026-1_FPGA_TermProject/RV32I_FPGA/Single_cycle/260511_Single_AXI_BRAM/Vitis/vitis_lenet5.c) 코드를 자동 생성하였습니다.

### 2.1 생성 경로
*   [vitis_lenet5.c](file:///home/hosung/Ho/2026-1_FPGA_Design/2026-1_FPGA_TermProject/RV32I_FPGA/Single_cycle/260511_Single_AXI_BRAM/Vitis/vitis_lenet5.c)

### 2.2 호스트 프로그램 주요 동작 흐름
1.  **기계어 로드**: `INST_BRAM_BASE` (0xA0000000) 주소에 LeNet-5 기계어 배열(`inst_array`, 4096 words)을 32비트 단위로 주입합니다.
2.  **데이터 및 가중치 로드**: `DATA_BRAM_BASE` (0xA0010000) 주소에 이미지 0번 데이터 및 가중치/바이어스 정보가 포함된 초기 메모리 배열(`data_array`, 11492 words)을 주입합니다.
3.  **데이터 캐시 플러시 (`Xil_DCacheFlush`)**: Zynq ARM 코어가 작성한 BRAM 영역이 캐시에 머물지 않고 실제 물리 메모리에 즉각 반영되도록 캐시 동기화를 수행합니다.
4.  **CPU 실행 및 대기**: 사용자에게 CPU Reset을 해제하도록 안내(VIO 버튼 클릭 또는 엔터 키 대기)합니다.
5.  **결과 모니터링**: 연산 완료 상태 블록(`s_block`)의 주소 버스를 직접 읽어와 예측 성공 플래그(`status`), 예측 레이블(`predicted_label`), 클래스별 원시 점수들을 UART 콘솔에 출력합니다.

---

## 3. 결론 및 향후 계획

실제 FPGA 보드 상에서 구동할 모든 기계어와 가중치 데이터 구조의 자동화가 완료되었습니다. 하드웨어 비트스트림 합성 및 Vitis 어플리케이션 적재 단계만 수행하면 실물 보드 위에서 초고속 LeNet-5 CFU 가속 SoC 검증이 완료됩니다.
