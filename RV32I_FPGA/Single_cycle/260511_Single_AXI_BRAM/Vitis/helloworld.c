#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"       // I/O 함수용
#include "xparameters.h"  // 하드웨어 파라미터
#include "xil_cache.h"    // 캐시 제어용 (매우 중요)
#include "sleep.h"

// 1. Vivado Address Editor에서 설정한 주소와 반드시 일치해야 함
#define INST_BRAM_BASE 0xA0000000  // Instruction BRAM (axi_bram_ctrl_0)
#define DATA_BRAM_BASE 0xA0010000  // Data BRAM (axi_bram_ctrl_1)

// 2. 실행할 RISC-V 기계어 배열 (예시: 이전 단계에서 생성한 imem.hex 내용)
u32 inst_array[] = {
    0x00500513, // addi x10, x0, 5
    0x00a00593, // addi x11, x0, 10
    0x00b50633, // add  x12, x10, x11
    0x00c02023, // sw   x12, 0(x0)     <-- ★추가됨: x12의 값을 데이터 메모리 0번지에 저장!
    0x0000006f  // j .                 <-- 무한 루프 (종료)
};

// 3. 연산에 사용할 초기 데이터 (필요 시)
u32 data_array[] = {
    0x00000001,
    0x00000002
};

int main() {
    init_platform();
    xil_printf("--- RISC-V SoC Control Start ---\n\r");

    // [단계 1] Instruction BRAM에 기계어 주입
    xil_printf("Loading Instructions...\n\r");
    for(int i=0; i < sizeof(inst_array)/4; i++) {
        Xil_Out32(INST_BRAM_BASE + (i*4), inst_array[i]);
    }

    // [단계 2] Data BRAM에 초기 데이터 주입
    xil_printf("Loading Data...\n\r");
    for(int i=0; i < sizeof(data_array)/4; i++) {
        Xil_Out32(DATA_BRAM_BASE + (i*4), data_array[i]);
    }

    // [단계 3] 데이터 캐시 플러시 (Zynq 시스템의 필수 관문)
    // ARM 코어가 쓴 데이터가 실제 BRAM(물리 메모리)에 즉시 도달하도록 보장합니다.
    Xil_DCacheFlush();

    xil_printf("Memory Setup Complete! Please release Reset in Vivado VIO.\n\r");

    // 사용자가 엔터를 치면 연산 결과를 확인하는 루틴
    getchar(); 

    // [단계 4] 연산 결과 읽기 (RISC-V가 연산을 끝냈다고 가정)
    u32 result = Xil_In32(DATA_BRAM_BASE + 0x0); // 예시 주소
    xil_printf("Computation Result from BRAM: 0x%08x\n\r", result);

    cleanup_platform();
    return 0;
}