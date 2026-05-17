#include "cnn_alu.h"

// ========================================================================
// 내부 BRAM (하드웨어 메모리) 선언 [Pragma 미적용 버전]
// ========================================================================
// 이 파일은 보고서(Report)에서 최적화 전/후를 비교하기 위한 기준 버전입니다.
//
// 중요한 원칙:
//   - 기능은 cnn_alu.cpp와 동일해야 합니다.
//   - 명령어 opcode, bias 처리, ReLU 순서, 32-slot padding 규약도 동일해야 합니다.
//   - 차이는 HLS 성능 최적화 pragma를 의도적으로 빼는 것입니다.
//
// cnn_alu.cpp에는 ARRAY_PARTITION, INLINE, PIPELINE 같은 pragma가 들어갑니다.
// 이 파일에서는 그런 최적화를 제거해서 HLS가 기본적으로 어떤 회로를 만드는지 봅니다.
// 따라서 이 파일은 빠르게 동작하기 위한 구현이 아니라, 성능 비교용 baseline입니다.
static ap_int<8> weight_buf[32]; 
static ap_int<8> act_buf[32];    

// 누산기와 load pointer도 최적화 버전과 동일한 상태 변수를 사용합니다.
static ap_int<32> acc_reg = 0;   

static int w_ptr = 0;
static int a_ptr = 0;

// 32비트 packed data에서 lane 번호에 해당하는 signed INT8 값을 뽑습니다.
// 최적화 버전(cnn_alu.cpp)은 lane0~lane3 helper를 따로 두고 INLINE합니다.
// 여기서는 비교용 baseline이므로 가변 lane index를 그대로 둡니다.
static ap_int<8> unpack_i8_no_pragma(ap_uint<32> data, int lane) {
    return (ap_int<8>)data(8 * lane + 7, 8 * lane);
}

// packed INT8 4개를 weight_buf 또는 act_buf에 저장합니다.
//
// ptr == 24인 tail packet에서는 24번 슬롯만 유효 데이터로 쓰고,
// 25~31번 padding 영역은 하드웨어에서 0으로 지웁니다.
// 이 규약은 최적화 버전과 반드시 같아야 합니다.
//
// 다만 여기서는 ARRAY_PARTITION이 없기 때문에 배열이 register array로 완전히
// 펼쳐지지 않고, HLS가 기본 메모리 구조를 선택합니다. 이 때문에 동시에 여러
// slot을 접근하는 성능이 최적화 버전보다 떨어질 수 있습니다.
static void load_pack4_no_pragma(ap_uint<32> data, ap_int<8> buf[32], int *ptr) {
    if (*ptr == 24) {
        buf[24] = unpack_i8_no_pragma(data, 0);
        for (int i = 25; i < 32; i++) {
            buf[i] = 0;
        }
        *ptr = 0;
    } else {
        for (int lane = 0; lane < 4; lane++) {
            int idx = *ptr + lane;
            if (idx < 32) {
                buf[idx] = unpack_i8_no_pragma(data, lane);
            }
        }

        *ptr = (*ptr + 4 >= 32) ? 0 : *ptr + 4;
    }
}

// 32-slot padded dot product의 pragma 미적용 버전입니다.
//
// 최적화 버전:
//   - 4-lane 누산기(sum0~sum3)
//   - PIPELINE II=1
//   - ARRAY_PARTITION된 버퍼에서 병렬 read
//
// 이 baseline 버전:
//   - 단일 sum에 순차적으로 누적
//   - PIPELINE/UNROLL 없음
//   - HLS가 기본 scheduling을 결정
//
// 기능적으로는 두 버전 모두 0~24번 유효 데이터와 25~31번 zero padding을
// 곱해서 같은 결과를 내야 합니다.
static ap_int<32> dot32_padded_no_pragma() {
    ap_int<32> sum = 0;
    for (int i = 0; i < 32; i++) {
        sum += (ap_int<16>)act_buf[i] * (ap_int<16>)weight_buf[i];
    }

    return sum;
}

void CNN_ALU_Top_NoPragma(
    ap_uint<32> rs1_data, 
    ap_uint<4>  cnn_op,   
    ap_uint<32> *rd_data  
) {
    // 핀 연결 인터페이스는 RV32I wrapper와의 포트 규격을 맞추기 위해 유지합니다.
    // 비교 대상은 datapath 최적화이므로, top-level port protocol은 최적화 버전과 같습니다.
    #pragma HLS INTERFACE ap_none port=rs1_data
    #pragma HLS INTERFACE ap_none port=cnn_op
    #pragma HLS INTERFACE ap_none port=rd_data
    #pragma HLS INTERFACE ap_ctrl_hs port=return

    // [핵심] 보고서 비교를 위해 ARRAY_PARTITION/PIPELINE/UNROLL pragma를 의도적으로 삭제했습니다.

    switch(cnn_op) {
        case CMD_LOAD_W_PACK4: {
            // signed INT8 weight 4개를 weight_buf에 저장합니다.
            load_pack4_no_pragma(rs1_data, weight_buf, &w_ptr);
            break;
        }
        case CMD_LOAD_A_PACK4: {
            // signed INT8 activation 4개를 act_buf에 저장합니다.
            load_pack4_no_pragma(rs1_data, act_buf, &a_ptr);
            break;
        }
        case CMD_START_MAC: {
            // ReLU를 적용하지 않은 순수 MAC 결과만 저장합니다.
            // Bias와 activation은 별도 명령으로 처리해야 합니다.
            acc_reg = dot32_padded_no_pragma();
            break;
        }
        case CMD_START_POOL: {
            // 2x2 Max Pooling: act_buf[0..3] 중 최댓값을 acc_reg에 저장합니다.
            ap_int<8> max1 = (act_buf[0] > act_buf[1]) ? act_buf[0] : act_buf[1];
            ap_int<8> max2 = (act_buf[2] > act_buf[3]) ? act_buf[2] : act_buf[3];
            ap_int<8> final_max = (max1 > max2) ? max1 : max2;
            acc_reg = final_max;
            break;
        }
        case CMD_GET_RES: {
            // 현재 누산 결과를 CPU로 반환합니다.
            *rd_data = acc_reg;
            break;
        }
        case CMD_CLEAR_ACC: {
            // 새 Conv/FC chunk 시작 전 누산기와 load pointer를 초기화합니다.
            acc_reg = 0;
            w_ptr = 0;
            a_ptr = 0;
            break;
        }
        case CMD_ACC_MAC: {
            // FC처럼 긴 dot product를 여러 25-slot chunk로 나눠 누적할 때 사용합니다.
            acc_reg += dot32_padded_no_pragma();
            break;
        }
        case CMD_ADD_BIAS: {
            // rs1_data 전체를 signed 32-bit bias로 보고 MAC 결과에 더합니다.
            acc_reg += (ap_int<32>)rs1_data;
            break;
        }
        case CMD_APPLY_RELU: {
            // MAC -> Bias 이후 필요한 경우에만 ReLU를 적용합니다.
            if (acc_reg < 0) {
                acc_reg = 0;
            }
            break;
        }
        default: {
            // 정의되지 않은 opcode는 상태를 바꾸지 않습니다.
            break;
        }
    }
}
