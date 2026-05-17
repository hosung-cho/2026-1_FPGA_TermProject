#include "cnn_alu.h"

#include <iostream>

// ========================================================================
// tb_cnn_alu.cpp
// ========================================================================
// 이 파일은 Vivado HLS C Simulation용 테스트벤치입니다.
// 실제 RV32I CPU나 RTL wrapper를 사용하지 않고, C++ 코드에서 CNN_ALU_Top()을
// 직접 호출하여 "CPU가 custom 명령어를 실행하는 상황"을 흉내 냅니다.
//
// 검증하는 항목:
//   1. INT8 4개를 32비트로 packing/unpacking하는 규약
//   2. 5x5 MAC 결과가 정답과 일치하는지
//   3. MAC 직후 ReLU가 걸리지 않고, Bias 이후 ReLU가 적용되는지
//   4. 2x2 Max Pooling이 정상 동작하는지
//   5. FC처럼 25개보다 긴 dot product를 여러 chunk로 누적할 수 있는지
//
// 주의:
//   이 테스트는 C-level 기능 검증입니다. 실제 RTL timing, ap_start/ap_done
//   handshake, RV32I pipeline stall은 별도 RTL testbench에서 검증해야 합니다.

// ------------------------------------------------------------------------
// signed INT8 값 4개를 하나의 32비트 word로 패킹합니다.
//
// CNN_ALU_Top의 LOAD 명령은 rs1_data를 다음과 같이 해석합니다.
//   bits [7:0]   -> lane0
//   bits [15:8]  -> lane1
//   bits [23:16] -> lane2
//   bits [31:24] -> lane3
//
// ap_uint<8>로 캐스팅하기 때문에 음수 int8 값도 2의 보수 bit pattern으로
// 그대로 들어갑니다. HLS 모듈 내부에서는 다시 ap_int<8>로 해석합니다.
// ------------------------------------------------------------------------
static ap_uint<32> pack4(int b0, int b1, int b2, int b3) {
    ap_uint<32> packed = 0;
    packed(7, 0) = (ap_uint<8>)b0;
    packed(15, 8) = (ap_uint<8>)b1;
    packed(23, 16) = (ap_uint<8>)b2;
    packed(31, 24) = (ap_uint<8>)b3;
    return packed;
}

// ------------------------------------------------------------------------
// weight 또는 activation chunk를 CNN_ALU 내부 buffer에 로드합니다.
//
// 하드웨어는 내부적으로 32-slot padded MAC을 수행하지만, 소프트웨어 쪽은
// 32개를 모두 보낼 필요가 없습니다. 대신 반드시 "논리 25-slot"까지는
// 전송해야 합니다.
//
// 예시:
//   - count = 25: 5x5 Conv window 전체를 전송
//   - count = 20: FC 마지막 chunk에서 실제 값 20개 + 0 padding 5개 전송
//
// loop가 i < 25까지 도는 이유:
//   ptr == 24인 마지막 packet을 CNN_ALU에 보내야 하드웨어가 25~31번
//   padding slot을 0으로 지웁니다. 이 마지막 packet을 생략하면 이전 chunk의
//   garbage 값이 padding 영역에 남아 MAC 결과가 틀어질 수 있습니다.
// ------------------------------------------------------------------------
static void load_25_slots(ap_uint<4> cmd, const int *values, int count) {
    for (int i = 0; i < 25; i += 4) {
        int b0 = (i < count) ? values[i] : 0;
        int b1 = (i + 1 < count) ? values[i + 1] : 0;
        int b2 = (i + 2 < count) ? values[i + 2] : 0;
        int b3 = (i + 3 < count) ? values[i + 3] : 0;
        ap_uint<32> ignored = 0;
        CNN_ALU_Top(pack4(b0, b1, b2, b3), cmd, &ignored);
    }
}

// FC/Conv 공통 chunk loader입니다.
// 현재는 load_25_slots()를 그대로 감싸지만, 호출부에서 "chunk를 로드한다"는
// 의도를 명확히 보이기 위해 별도 함수로 둡니다.
static void load_chunk(ap_uint<4> cmd, const int *values, int count) {
    load_25_slots(cmd, values, count);
}

// CNN_ALU의 CMD_GET_RES 명령을 호출해 acc_reg 값을 읽습니다.
// rd_data는 ap_uint<32> 포트이지만 결과는 signed 누산값이므로 ap_int<32>로
// 다시 해석한 뒤 C++ int로 변환합니다.
static int read_result() {
    ap_uint<32> result = 0;
    CNN_ALU_Top(0, CMD_GET_RES, &result);
    return (int)(ap_int<32>)result;
}

static int requant_relu_ref(int acc, int multiplier) {
    if (acc <= 0) {
        return 0;
    }

    long long product = (long long)acc * (long long)multiplier;
    long long rounded = product + (1LL << (REQUANT_SHIFT - 1));
    int scaled = (int)(rounded >> REQUANT_SHIFT);

    if (scaled > 127) {
        return 127;
    }

    return scaled;
}

int main() {
    // =====================================================================
    // Test 1: 기본 5x5 MAC
    // =====================================================================
    // weights = 1..25, activations = 모두 2로 설정합니다.
    // 기대값은 2 * (1 + 2 + ... + 25) = 650입니다.
    // 이 테스트는 LOAD_W_PACK4, LOAD_A_PACK4, START_MAC, GET_RES의
    // 기본 데이터 경로를 검증합니다.
    int weights[25];
    int activations[25];

    int expected_mac = 0;
    for (int i = 0; i < 25; i++) {
        weights[i] = i + 1;
        activations[i] = 2;
        expected_mac += weights[i] * activations[i];
    }

    // CPU가 custom 명령어를 여러 번 실행하듯 weight와 activation을 먼저 로드합니다.
    load_25_slots(CMD_LOAD_W_PACK4, weights, 25);
    load_25_slots(CMD_LOAD_A_PACK4, activations, 25);

    // START_MAC은 순수 dot product만 수행합니다. ReLU나 bias는 적용하지 않습니다.
    ap_uint<32> ignored = 0;
    CNN_ALU_Top(0, CMD_START_MAC, &ignored);
    int got_mac = read_result();
    if (got_mac != expected_mac) {
        std::cout << "MAC failed: got " << got_mac
                  << ", expected " << expected_mac << std::endl;
        return 1;
    }

    // =====================================================================
    // Test 2: MAC -> Bias -> ReLU 순서 검증
    // =====================================================================
    // LeNet-5를 포함한 일반적인 NN 연산 순서는 다음과 같습니다.
    //   MAC 결과 -> Bias 덧셈 -> Activation(ReLU 등)
    //
    // 이 테스트는 START_MAC에서 음수 결과를 바로 0으로 자르지 않는지 확인합니다.
    // weights = -1, activations = 2, 25개이므로 MAC 결과는 -50입니다.
    // 이후 bias +60을 더하면 +10이 되고, ReLU 후에도 +10이어야 합니다.
    for (int i = 0; i < 25; i++) {
        weights[i] = -1;
        activations[i] = 2;
    }

    load_25_slots(CMD_LOAD_W_PACK4, weights, 25);
    load_25_slots(CMD_LOAD_A_PACK4, activations, 25);
    CNN_ALU_Top(0, CMD_START_MAC, &ignored);
    int got_negative_mac = read_result();
    if (got_negative_mac != -50) {
        std::cout << "Negative MAC failed: got " << got_negative_mac
                  << ", expected -50" << std::endl;
        return 1;
    }

    // Bias는 CMD_ADD_BIAS에서 rs1_data 전체를 signed 32-bit로 해석해 acc_reg에 더합니다.
    CNN_ALU_Top((ap_uint<32>)(ap_int<32>)60, CMD_ADD_BIAS, &ignored);
    int got_biased_mac = read_result();
    if (got_biased_mac != 10) {
        std::cout << "Bias after negative MAC failed: got " << got_biased_mac
                  << ", expected 10" << std::endl;
        return 1;
    }

    // ReLU는 명시적으로 CMD_APPLY_RELU를 호출할 때만 적용됩니다.
    CNN_ALU_Top(0, CMD_APPLY_RELU, &ignored);
    int got_relu = read_result();
    if (got_relu != 10) {
        std::cout << "ReLU after bias failed: got " << got_relu
                  << ", expected 10" << std::endl;
        return 1;
    }

    // =====================================================================
    // Test 2-1: activation과 weight가 모두 음수인 INT8 MAC 검증
    // =====================================================================
    // 이 테스트는 packed 32-bit word 안에 들어간 음수 INT8 값이 HLS 내부에서
    // ap_int<8>로 올바르게 sign-extension 되는지 확인합니다.
    //
    // 각 lane의 곱은 다음과 같습니다.
    //   (-1 * -2) + (-2 * -3) + (-3 * -4) + ... + (-25 * -26)
    //
    // 음수와 음수의 곱은 양수여야 하므로, 여기서 값이 틀리면 packing/unpacking
    // 또는 ap_uint -> ap_int 캐스팅 쪽의 부호 처리에 문제가 있다는 뜻입니다.
    int neg_acts[25];
    int neg_weights[25];
    int expected_neg_neg = 0;
    for (int i = 0; i < 25; i++) {
        neg_acts[i] = -(i + 1);
        neg_weights[i] = -(i + 2);
        expected_neg_neg += neg_acts[i] * neg_weights[i];
    }

    load_25_slots(CMD_LOAD_A_PACK4, neg_acts, 25);
    load_25_slots(CMD_LOAD_W_PACK4, neg_weights, 25);
    CNN_ALU_Top(0, CMD_START_MAC, &ignored);
    int got_neg_neg = read_result();
    if (got_neg_neg != expected_neg_neg) {
        std::cout << "Negative activation/weight MAC failed: got " << got_neg_neg
                  << ", expected " << expected_neg_neg << std::endl;
        return 1;
    }

    // =====================================================================
    // Test 3: 2x2 Max Pooling
    // =====================================================================
    // Max pooling은 act_buf[0..3]에 들어온 네 값 중 최댓값을 선택합니다.
    // 여기서는 [-3, 17, 4, 11]을 넣었으므로 결과는 17이어야 합니다.
    ap_uint<32> pool_packet = pack4(-3, 17, 4, 11);
    CNN_ALU_Top(pool_packet, CMD_LOAD_A_PACK4, &ignored);
    CNN_ALU_Top(0, CMD_START_POOL, &ignored);
    int got_pool = read_result();
    if (got_pool != 17) {
        std::cout << "Max pool failed: got " << got_pool
                  << ", expected 17" << std::endl;
        return 1;
    }

    // =====================================================================
    // Test 4: Fully Connected 누적 MAC + Bias + ReLU
    // =====================================================================
    // FC layer의 한 output neuron은 보통 입력 vector 전체와 weight vector의
    // dot product입니다. 예를 들어 FC1은 120개 입력을 사용합니다.
    //
    // CNN_ALU의 한 번 MAC은 25-slot chunk만 처리하므로, 120개 입력은
    // 다음처럼 여러 번 나눠 누적합니다.
    //   25 + 25 + 25 + 25 + 20
    //
    // 마지막 20개 chunk는 load_25_slots()가 20~24번 슬롯을 0으로 채워 보내고,
    // 하드웨어가 25~31번 슬롯을 0으로 지웁니다.
    int fc_inputs[120];
    int fc_weights[120];
    int expected_fc = 0;
    int fc_bias = 13;
    for (int i = 0; i < 120; i++) {
        fc_inputs[i] = (i % 7) - 3;
        fc_weights[i] = (i % 5) - 2;
        expected_fc += fc_inputs[i] * fc_weights[i];
    }
    expected_fc += fc_bias;

    // 새 FC output neuron 계산을 시작하므로 누산기와 load pointer를 초기화합니다.
    CNN_ALU_Top(0, CMD_CLEAR_ACC, &ignored);
    for (int offset = 0; offset < 120; offset += 25) {
        int count = (offset + 25 <= 120) ? 25 : 120 - offset;
        // 현재 chunk의 input activation과 weight를 각각 로드합니다.
        load_chunk(CMD_LOAD_A_PACK4, &fc_inputs[offset], count);
        load_chunk(CMD_LOAD_W_PACK4, &fc_weights[offset], count);
        // 현재 chunk dot product를 acc_reg에 누적합니다.
        CNN_ALU_Top(0, CMD_ACC_MAC, &ignored);
    }
    // FC bias를 더한 뒤 ReLU를 적용합니다.
    // 최종 FC2 logits처럼 activation이 필요 없는 레이어라면 APPLY_RELU는 생략할 수 있습니다.
    CNN_ALU_Top((ap_uint<32>)(ap_int<32>)fc_bias, CMD_ADD_BIAS, &ignored);
    CNN_ALU_Top(0, CMD_APPLY_RELU, &ignored);
    int got_fc = read_result();
    int expected_fc_relu = expected_fc < 0 ? 0 : expected_fc;
    if (got_fc != expected_fc_relu) {
        std::cout << "FC accumulate failed: got " << got_fc
                  << ", expected " << expected_fc_relu << std::endl;
        return 1;
    }

    // =====================================================================
    // Test 5: INT32 accumulator -> INT8 activation requantization + ReLU
    // =====================================================================
    // INT8 x INT8 MAC 결과는 acc_reg에 INT32로 누적되므로 다음 layer로 넘기기 전에
    // 다시 INT8 범위로 줄여야 합니다. CMD_REQUANT_RELU는 rs1_data로 전달받은
    // fixed-point multiplier와 REQUANT_SHIFT를 사용해 다음 수식을 수행합니다.
    //
    //   output_int8 = clamp_relu(round(acc_reg * multiplier / 2^REQUANT_SHIFT))
    //
    // 실제 layer별 multiplier는 export_lenet_int8.py가 scale 파일을 바탕으로 생성합니다.
    int acc_for_requant = 100000;
    int multiplier = 827;
    int expected_requant = requant_relu_ref(acc_for_requant, multiplier);

    CNN_ALU_Top(0, CMD_CLEAR_ACC, &ignored);
    CNN_ALU_Top((ap_uint<32>)(ap_int<32>)acc_for_requant, CMD_ADD_BIAS, &ignored);
    CNN_ALU_Top((ap_uint<32>)(ap_int<32>)multiplier, CMD_REQUANT_RELU, &ignored);
    int got_requant = read_result();
    if (got_requant != expected_requant) {
        std::cout << "Requant failed: got " << got_requant
                  << ", expected " << expected_requant << std::endl;
        return 1;
    }

    // 음수 누산값은 ReLU에 의해 0이 되어야 합니다.
    CNN_ALU_Top(0, CMD_CLEAR_ACC, &ignored);
    CNN_ALU_Top((ap_uint<32>)(ap_int<32>)-5000, CMD_ADD_BIAS, &ignored);
    CNN_ALU_Top((ap_uint<32>)(ap_int<32>)multiplier, CMD_REQUANT_RELU, &ignored);
    int got_requant_relu_zero = read_result();
    if (got_requant_relu_zero != 0) {
        std::cout << "Requant ReLU negative clamp failed: got "
                  << got_requant_relu_zero << ", expected 0" << std::endl;
        return 1;
    }

    // 큰 양수는 INT8 activation의 최댓값인 127로 saturation 되어야 합니다.
    CNN_ALU_Top(0, CMD_CLEAR_ACC, &ignored);
    CNN_ALU_Top((ap_uint<32>)(ap_int<32>)10000000, CMD_ADD_BIAS, &ignored);
    CNN_ALU_Top((ap_uint<32>)(ap_int<32>)multiplier, CMD_REQUANT_RELU, &ignored);
    int got_requant_sat = read_result();
    if (got_requant_sat != 127) {
        std::cout << "Requant saturation failed: got " << got_requant_sat
                  << ", expected 127" << std::endl;
        return 1;
    }

    std::cout << "CNN_ALU_Top C simulation passed" << std::endl;
    return 0;
}
