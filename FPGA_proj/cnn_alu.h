#ifndef _CNN_ALU_H_
#define _CNN_ALU_H_

#include "ap_int.h"

// ========================================================================
// CNN ALU 명령어 정의
// ========================================================================
// 이 값은 RV32I 쪽 디코더/Wrapper가 CNN_ALU_Top의 cnn_op 포트로 전달하는
// 명령 코드입니다. 처음 계획은 funct3 3비트만 사용하는 구조였지만,
// FC/Conv에서 필요한 Bias 덧셈까지 하드웨어 명령으로 처리하기 위해
// 현재 cnn_op는 4비트 확장 opcode로 사용합니다.
//
// 기본 사용 흐름:
//   1. CMD_CLEAR_ACC
//   2. CMD_LOAD_A_PACK4 / CMD_LOAD_W_PACK4 반복
//   3. CMD_START_MAC 또는 CMD_ACC_MAC
//   4. CMD_ADD_BIAS
//   5. CMD_APPLY_RELU (필요한 레이어에서만 사용, FC2 logits는 생략 가능)
//   6. CMD_GET_RES
#define CMD_LOAD_W_PACK4 0
#define CMD_LOAD_A_PACK4 1
#define CMD_START_MAC    2
#define CMD_GET_RES      3
#define CMD_START_POOL   4
#define CMD_CLEAR_ACC    5
#define CMD_ACC_MAC      6
#define CMD_APPLY_RELU   7
#define CMD_ADD_BIAS     8
#define CMD_REQUANT_RELU 9
#define CMD_MAC_PACK4    10
#define CMD_POOL4_READ   11
#define CMD_BIAS_REQUANT_RELU_READ 12

// acc_int32를 다음 layer의 INT8 activation으로 줄일 때 사용하는 고정 소수점 shift입니다.
// 실제 layer별 scale 차이는 rs1_data로 전달되는 32-bit multiplier에 반영합니다.
// output_int8 = clamp_relu((acc_int32 * multiplier + rounding) >> REQUANT_SHIFT)
#define REQUANT_SHIFT    20

// ========================================================================
// HLS Top 함수 선언
// ========================================================================
// rs1_data:
//   RV32I 레지스터에서 전달되는 32비트 입력 버스입니다.
//   LOAD 명령에서는 INT8 값 4개가 little-endian 형태로 패킹됩니다.
//     lane0 = bits [7:0]
//     lane1 = bits [15:8]
//     lane2 = bits [23:16]
//     lane3 = bits [31:24]
//   ADD_BIAS 명령에서는 rs1_data 전체를 signed 32-bit bias로 해석합니다.
//
// cnn_op:
//   위 CMD_* 값 중 하나입니다. 4비트이므로 RTL Wrapper도 4비트로 맞춰야 합니다.
//
// rd_data:
//   GET_RES 명령에서 acc_reg 값을 CPU로 반환하는 출력 포트입니다.
void CNN_ALU_Top(
    ap_uint<32> rs1_data,
    ap_uint<32> rs2_data,
    ap_uint<4>  cnn_op,
    ap_uint<32> *rd_data
);

#endif
