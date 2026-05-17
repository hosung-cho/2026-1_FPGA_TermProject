#include "cnn_alu.h"

// ========================================================================
// 내부 BRAM (하드웨어 메모리) 선언
// ========================================================================
// 이 모듈은 5x5 convolution의 한 output pixel 또는 FC의 한 partial dot
// product를 계산하는 작은 CNN 전용 ALU입니다.
//
// 실제 5x5 MAC에 필요한 값은 25개이지만, 내부 버퍼는 32칸입니다.
// 이유는 4개 INT8 값을 한 번에 처리하는 4-lane SIMD 구조와 맞추기 위해서입니다.
// 25개는 4로 나누어 떨어지지 않기 때문에 그대로 factor=4 unroll을 걸면
// HLS가 tail 처리용 제어 로직과 mux를 더 만들 수 있습니다.
// 그래서 25개 유효 데이터 + 7개 zero padding = 32개 슬롯으로 정렬합니다.
//
// 중요 소프트웨어 규약:
//   - 각 MAC chunk마다 논리적으로 25개 슬롯까지는 반드시 전송해야 합니다.
//   - 값이 25개보다 적은 FC 마지막 chunk는 부족한 20~24번 슬롯을 0으로 보내야 합니다.
//   - 24번 슬롯이 들어오는 순간 load_pack4()가 25~31번 슬롯을 하드웨어에서 0으로 지웁니다.
//   - 즉 소프트웨어가 32개까지 보낼 필요는 없지만, 24번 슬롯까지는 도달해야 합니다.
//
// ap_int<8>은 signed INT8입니다. 양자화된 activation/weight가 -128~127 범위라고
// 가정하고 곱셈 결과는 ap_int<32> 누산기에 누적합니다.
static ap_int<8> weight_buf[32]; 
static ap_int<8> act_buf[32];    

// MAC, bias, activation 적용 중간 결과를 저장하는 32비트 누산기입니다.
// Conv 단일 5x5 MAC에서는 CMD_START_MAC이 이 값을 덮어씁니다.
// FC처럼 긴 vector dot product에서는 CMD_CLEAR_ACC 이후 CMD_ACC_MAC을 여러 번
// 호출해서 이 레지스터에 partial sum을 누적합니다.
static ap_int<32> acc_reg = 0;   

// weight_buf/act_buf의 다음 write 위치입니다.
// LOAD_*_PACK4 명령이 들어올 때마다 4칸씩 증가하며, 24번 슬롯 처리 후 0으로 돌아갑니다.
// CMD_CLEAR_ACC도 포인터를 0으로 초기화해서 새 Conv/FC chunk 시작점을 명확히 합니다.
static int w_ptr = 0;
static int a_ptr = 0;

// ------------------------------------------------------------------------
// 32비트 packed data에서 signed INT8 lane을 추출하는 helper 함수들입니다.
// HLS bit range 문법 data(high, low)를 사용합니다.
// lane0이 최하위 8비트이므로 소프트웨어도 같은 endian 규약으로 패킹해야 합니다.
// ------------------------------------------------------------------------
static ap_int<8> lane0(ap_uint<32> data) {
#pragma HLS INLINE
    return (ap_int<8>)data(7, 0);
}

static ap_int<8> lane1(ap_uint<32> data) {
#pragma HLS INLINE
    return (ap_int<8>)data(15, 8);
}

static ap_int<8> lane2(ap_uint<32> data) {
#pragma HLS INLINE
    return (ap_int<8>)data(23, 16);
}

static ap_int<8> lane3(ap_uint<32> data) {
#pragma HLS INLINE
    return (ap_int<8>)data(31, 24);
}

// ------------------------------------------------------------------------
// 32비트 packed data 1개를 내부 버퍼에 저장합니다.
//
// 일반 packet:
//   ptr = 0,4,8,12,16,20일 때는 lane0~lane3을 그대로 4칸에 씁니다.
//
// tail packet:
//   ptr = 24일 때는 5x5 MAC의 마지막 유효값 하나만 buf[24]에 씁니다.
//   그리고 buf[25]~buf[31]은 하드웨어에서 직접 0으로 지웁니다.
//   이 처리 덕분에 이전 연산의 garbage data가 padding 영역에 남아
//   dot32_padded()에 섞이는 문제를 막습니다.
//
// 주의:
//   FC 마지막 chunk가 20개만 남은 경우에도 소프트웨어는 20~24번 슬롯까지
//   0을 채워 보내야 합니다. 그래야 ptr=24 분기가 실행되어 25~31번도 0으로 정리됩니다.
// ------------------------------------------------------------------------
static void load_pack4(ap_uint<32> data, ap_int<8> buf[32], int *ptr) {
#pragma HLS INLINE
    switch (*ptr) {
        case 0:
            buf[0] = lane0(data);
            buf[1] = lane1(data);
            buf[2] = lane2(data);
            buf[3] = lane3(data);
            *ptr = 4;
            break;
        case 4:
            buf[4] = lane0(data);
            buf[5] = lane1(data);
            buf[6] = lane2(data);
            buf[7] = lane3(data);
            *ptr = 8;
            break;
        case 8:
            buf[8] = lane0(data);
            buf[9] = lane1(data);
            buf[10] = lane2(data);
            buf[11] = lane3(data);
            *ptr = 12;
            break;
        case 12:
            buf[12] = lane0(data);
            buf[13] = lane1(data);
            buf[14] = lane2(data);
            buf[15] = lane3(data);
            *ptr = 16;
            break;
        case 16:
            buf[16] = lane0(data);
            buf[17] = lane1(data);
            buf[18] = lane2(data);
            buf[19] = lane3(data);
            *ptr = 20;
            break;
        case 20:
            buf[20] = lane0(data);
            buf[21] = lane1(data);
            buf[22] = lane2(data);
            buf[23] = lane3(data);
            *ptr = 24;
            break;
        case 24:
            buf[24] = lane0(data);
            buf[25] = 0;
            buf[26] = 0;
            buf[27] = 0;
            buf[28] = 0;
            buf[29] = 0;
            buf[30] = 0;
            buf[31] = 0;
            *ptr = 0;
            break;
        default:
            *ptr = 0;
            break;
    }
}

// ------------------------------------------------------------------------
// 32-slot padded dot product.
//
// 계산 대상:
//   sum(act_buf[i] * weight_buf[i]), i = 0..31
//
// 실제 유효 데이터는 0..24이고, 25..31은 load_pack4()가 0으로 보장합니다.
// 따라서 결과는 5x5 25개 dot product와 같습니다.
//
// 4-lane 구조:
//   한 loop iteration에서 4개 lane을 동시에 계산합니다.
//   sum0..sum3을 분리한 이유는 하나의 sum에 4개 곱셈 결과를 계속 더하면
//   HLS가 긴 adder chain을 만들 수 있기 때문입니다.
//   lane별 partial sum을 따로 누적한 뒤 마지막에 4개만 합치면
//   critical path와 mux 구조가 더 안정적으로 나옵니다.
//
// 합성 의도:
//   - PIPELINE II=1: 매 cycle 한 iteration 처리
//   - iteration 8번 x 4 lane = 32 slot 처리
// ------------------------------------------------------------------------
static ap_int<32> dot32_padded() {
#pragma HLS INLINE
    ap_int<32> sum0 = 0;
    ap_int<32> sum1 = 0;
    ap_int<32> sum2 = 0;
    ap_int<32> sum3 = 0;
MAC_LOOP:
    for (int i = 0; i < 8; i++) {
#pragma HLS PIPELINE II=1
        int base = i << 2;
        sum0 += (ap_int<16>)act_buf[base] * (ap_int<16>)weight_buf[base];
        sum1 += (ap_int<16>)act_buf[base + 1] * (ap_int<16>)weight_buf[base + 1];
        sum2 += (ap_int<16>)act_buf[base + 2] * (ap_int<16>)weight_buf[base + 2];
        sum3 += (ap_int<16>)act_buf[base + 3] * (ap_int<16>)weight_buf[base + 3];
    }

    return sum0 + sum1 + sum2 + sum3;
}

void CNN_ALU_Top(
    ap_uint<32> rs1_data, 
    ap_uint<4>  cnn_op,   
    ap_uint<32> *rd_data  
) {
    // ========================================================================
    // HLS 인터페이스 설정
    // ========================================================================
    // ap_none:
    //   rs1_data, cnn_op, rd_data를 AXI 같은 bus protocol 없이 일반 wire 포트로 만듭니다.
    //   RV32I EX stage 또는 wrapper에서 직접 배선하기 위한 설정입니다.
    //
    // ap_ctrl_hs:
    //   ap_start, ap_done, ap_idle, ap_ready 핸드셰이크 포트를 생성합니다.
    //   RV32I 파이프라인은 긴 MAC 명령 동안 ap_done을 기준으로 stall을 걸 수 있습니다.
    #pragma HLS INTERFACE ap_none port=rs1_data
    #pragma HLS INTERFACE ap_none port=cnn_op
    #pragma HLS INTERFACE ap_none port=rd_data
    #pragma HLS INTERFACE ap_ctrl_hs port=return

    // ARRAY_PARTITION complete:
    //   weight_buf/act_buf를 BRAM 하나로 두지 않고 32개의 독립 register처럼 펼칩니다.
    //   이렇게 해야 dot32_padded()가 같은 cycle에 여러 lane을 동시에 읽을 수 있습니다.
    //   BRAM 포트 수 제한으로 인한 병목을 피하기 위한 핵심 pragma입니다.
    #pragma HLS ARRAY_PARTITION variable=weight_buf complete dim=1
    #pragma HLS ARRAY_PARTITION variable=act_buf complete dim=1

    // ========================================================================
    // 명령어 해독 및 실행 (FSM 로직)
    // ========================================================================
    switch(cnn_op) {
        
        case CMD_LOAD_W_PACK4: {
            // 32비트 rs1_data에 packed된 signed INT8 weight 4개를 weight_buf에 저장합니다.
            // 소프트웨어는 weight를 lane0..lane3 순서로 패킹해야 합니다.
            load_pack4(rs1_data, weight_buf, &w_ptr);
            break;
        }
        case CMD_LOAD_A_PACK4: {
            // 32비트 rs1_data에 packed된 signed INT8 activation/pixel 4개를 act_buf에 저장합니다.
            // Conv에서는 sliding window의 5x5 activation, FC에서는 input vector chunk가 들어옵니다.
            load_pack4(rs1_data, act_buf, &a_ptr);
            break;
        }
        case CMD_START_MAC: {
            // 단일 5x5 MAC 결과를 acc_reg에 저장합니다.
            // 여기서는 ReLU를 적용하지 않습니다.
            // 올바른 신경망 순서는 MAC -> Bias -> Activation이므로,
            // 필요하면 이후 CMD_ADD_BIAS, CMD_APPLY_RELU를 명시적으로 호출해야 합니다.
            acc_reg = dot32_padded();
            break;
        }
        case CMD_START_POOL: {
            // 2x2 Max Pooling 한 칸을 계산합니다.
            // 입력은 act_buf[0..3]에 들어온다고 가정합니다.
            // Average pooling과 달리 덧셈/나눗셈 없이 comparator tree만 사용합니다.
            ap_int<8> max1 = (act_buf[0] > act_buf[1]) ? act_buf[0] : act_buf[1];
            ap_int<8> max2 = (act_buf[2] > act_buf[3]) ? act_buf[2] : act_buf[3];
            ap_int<8> final_max = (max1 > max2) ? max1 : max2;
            acc_reg = final_max;
            break;
        }
        case CMD_GET_RES: {
            // 현재 acc_reg 값을 CPU로 반환합니다.
            // rd_data는 ap_none 포트이므로 wrapper/CPU 쪽에서 ap_done 타이밍에 맞춰 읽어야 합니다.
            *rd_data = acc_reg;
            break;
        }
        case CMD_CLEAR_ACC: {
            // 새 Conv/FC 연산을 시작하기 위한 초기화 명령입니다.
            // acc_reg뿐 아니라 load pointer도 초기화해서 다음 LOAD가 buf[0]부터 시작하게 합니다.
            acc_reg = 0;
            w_ptr = 0;
            a_ptr = 0;
            break;
        }
        case CMD_ACC_MAC: {
            // FC처럼 입력 길이가 25보다 긴 dot product를 계산할 때 사용합니다.
            // 현재 25-slot chunk의 dot product를 기존 acc_reg에 누적합니다.
            // 예: FC1 120개 입력 = 25 + 25 + 25 + 25 + 20(나머지 5개 zero fill)
            acc_reg += dot32_padded();
            break;
        }
        case CMD_ADD_BIAS: {
            // Bias를 더합니다.
            // rs1_data 전체를 signed 32-bit 값으로 해석합니다.
            // Bias는 반드시 MAC/ACC_MAC 이후, ReLU 이전에 더해야 합니다.
            acc_reg += (ap_int<32>)rs1_data;
            break;
        }
        case CMD_APPLY_RELU: {
            // ReLU activation입니다.
            // Conv/FC 중 ReLU가 필요한 레이어에서만 호출합니다.
            // FC2처럼 최종 logit을 그대로 비교하는 레이어에서는 생략할 수 있습니다.
            if (acc_reg < 0) {
                acc_reg = 0;
            }
            break;
        }
        default: {
            // 정의되지 않은 opcode는 상태를 바꾸지 않습니다.
            // 디버깅 시 wrapper/decoder 쪽 opcode 폭과 CMD_* 값이 맞는지 확인하세요.
            break;
        }
    }
}
