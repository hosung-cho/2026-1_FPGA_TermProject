#include "cnn_alu.h"
#include "lenet_int8_params.h"

#include <cstdint>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

#ifdef DUMP_CONV3_FIXTURE
static void write_hex8(std::ofstream &out, int value) {
    static const char hex[] = "0123456789abcdef";
    unsigned v = (unsigned)((uint8_t)(int8_t)value);
    out << hex[(v >> 4) & 0xf] << hex[v & 0xf] << "\n";
}

static void write_hex32(std::ofstream &out, int32_t value) {
    static const char hex[] = "0123456789abcdef";
    uint32_t v = (uint32_t)value;
    for (int shift = 28; shift >= 0; shift -= 4) {
        out << hex[(v >> shift) & 0xf];
    }
    out << "\n";
}

static void dump_conv3_fixture(const int8_t p2[16][5][5], const int8_t c3[120]) {
    std::ofstream p2_file("conv3_p2.mem");
    for (int ic = 0; ic < 16; ic++) {
        for (int kr = 0; kr < 5; kr++) {
            for (int kc = 0; kc < 5; kc++) {
                write_hex8(p2_file, p2[ic][kr][kc]);
            }
        }
    }

    std::ofstream w_file("conv3_weight_oc0_7.mem");
    for (int oc = 0; oc < 8; oc++) {
        for (int ic = 0; ic < 16; ic++) {
            for (int kr = 0; kr < 5; kr++) {
                for (int kc = 0; kc < 5; kc++) {
                    write_hex8(w_file, conv3_weight_int8[oc][ic][kr][kc]);
                }
            }
        }
    }

    std::ofstream bias_file("conv3_bias_oc0_7.mem");
    for (int oc = 0; oc < 8; oc++) {
        write_hex32(bias_file, conv3_bias_int32[oc]);
    }

    std::ofstream expected_file("conv3_expected_oc0_7.mem");
    for (int oc = 0; oc < 8; oc++) {
        write_hex32(expected_file, c3[oc]);
    }
}
#endif

static ap_uint<32> pack4(int b0, int b1, int b2, int b3) {
    ap_uint<32> packed = 0;
    packed(7, 0) = (ap_uint<8>)b0;
    packed(15, 8) = (ap_uint<8>)b1;
    packed(23, 16) = (ap_uint<8>)b2;
    packed(31, 24) = (ap_uint<8>)b3;
    return packed;
}

static void alu_clear() {
    ap_uint<32> ignored = 0;
    CNN_ALU_Top(0, 0, CMD_CLEAR_ACC, &ignored);
}

static void alu_load_25(ap_uint<4> cmd, const int *values) {
    ap_uint<32> ignored = 0;
    for (int i = 0; i < 25; i += 4) {
        int b0 = values[i];
        int b1 = (i + 1 < 25) ? values[i + 1] : 0;
        int b2 = (i + 2 < 25) ? values[i + 2] : 0;
        int b3 = (i + 3 < 25) ? values[i + 3] : 0;
        CNN_ALU_Top(pack4(b0, b1, b2, b3), 0, cmd, &ignored);
    }
}

static void alu_mac_25(const int *act, const int *weight) {
    ap_uint<32> ignored = 0;
    for (int i = 0; i < 25; i += 4) {
        int a0 = act[i];
        int a1 = (i + 1 < 25) ? act[i + 1] : 0;
        int a2 = (i + 2 < 25) ? act[i + 2] : 0;
        int a3 = (i + 3 < 25) ? act[i + 3] : 0;
        int w0 = weight[i];
        int w1 = (i + 1 < 25) ? weight[i + 1] : 0;
        int w2 = (i + 2 < 25) ? weight[i + 2] : 0;
        int w3 = (i + 3 < 25) ? weight[i + 3] : 0;
        CNN_ALU_Top(pack4(a0, a1, a2, a3), pack4(w0, w1, w2, w3), CMD_MAC_PACK4, &ignored);
    }
}

static int alu_read() {
    ap_uint<32> result = 0;
    CNN_ALU_Top(0, 0, CMD_GET_RES, &result);
    return (int)(ap_int<32>)result;
}

static int alu_requant_relu(int32_t bias, int32_t multiplier) {
    ap_uint<32> result = 0;
    CNN_ALU_Top((ap_uint<32>)(ap_int<32>)bias,
                (ap_uint<32>)(ap_int<32>)multiplier,
                CMD_BIAS_REQUANT_RELU_READ,
                &result);
    return (int)(ap_int<32>)result;
}

static int alu_pool4(int a0, int a1, int a2, int a3) {
    ap_uint<32> result = 0;
    CNN_ALU_Top(pack4(a0, a1, a2, a3), 0, CMD_POOL4_READ, &result);
    return (int)(ap_int<32>)result;
}

static bool load_int8_txt(const char *path, int8_t image[32][32], int *label) {
    std::ifstream file(path);
    std::string fallback_path;
    if (!file.is_open()) {
        fallback_path = std::string("../../../../") + path;
        file.open(fallback_path.c_str());
    }
    if (!file.is_open()) {
        fallback_path = std::string("../../../") + path;
        file.open(fallback_path.c_str());
    }
    if (!file.is_open()) {
        return false;
    }

    std::string line;
    *label = -1;
    while (std::getline(file, line)) {
        if (line.find("Label:") == 0) {
            std::stringstream ss(line.substr(line.find(":") + 1));
            ss >> *label;
        }
        if (line.size() > 0 && line[0] == 'r') {
            int row = -1;
            char rchar = 0;
            char colon = 0;
            std::stringstream ss(line);
            ss >> rchar >> row >> colon;
            for (int col = 0; col < 32; col++) {
                int value = 0;
                ss >> value;
                image[row][col] = (int8_t)value;
            }
        }
    }

    return *label >= 0;
}

static void run_conv1(const int8_t input[32][32], int8_t output[6][28][28]) {
    ap_uint<32> ignored = 0;
    int act[25];
    int weight[25];

    for (int oc = 0; oc < 6; oc++) {
        for (int row = 0; row < 28; row++) {
            for (int col = 0; col < 28; col++) {
                int idx = 0;
                for (int kr = 0; kr < 5; kr++) {
                    for (int kc = 0; kc < 5; kc++) {
                        act[idx] = input[row + kr][col + kc];
                        weight[idx] = conv1_weight_int8[oc][0][kr][kc];
                        idx++;
                    }
                }

                alu_clear();
                alu_mac_25(act, weight);
                output[oc][row][col] =
                    (int8_t)alu_requant_relu(conv1_bias_int32[oc], conv1_requant_multiplier);
            }
        }
    }
}

static void run_pool1(const int8_t input[6][28][28], int8_t output[6][14][14]) {
    for (int ch = 0; ch < 6; ch++) {
        for (int row = 0; row < 14; row++) {
            for (int col = 0; col < 14; col++) {
                output[ch][row][col] = (int8_t)alu_pool4(
                    input[ch][row * 2][col * 2],
                    input[ch][row * 2][col * 2 + 1],
                    input[ch][row * 2 + 1][col * 2],
                    input[ch][row * 2 + 1][col * 2 + 1]);
            }
        }
    }
}

static void run_conv2(const int8_t input[6][14][14], int8_t output[16][10][10]) {
    ap_uint<32> ignored = 0;
    int act[25];
    int weight[25];

    for (int oc = 0; oc < 16; oc++) {
        for (int row = 0; row < 10; row++) {
            for (int col = 0; col < 10; col++) {
                alu_clear();
                for (int ic = 0; ic < 6; ic++) {
                    int idx = 0;
                    for (int kr = 0; kr < 5; kr++) {
                        for (int kc = 0; kc < 5; kc++) {
                            act[idx] = input[ic][row + kr][col + kc];
                            weight[idx] = conv2_weight_int8[oc][ic][kr][kc];
                            idx++;
                        }
                    }
                    alu_mac_25(act, weight);
                }
                output[oc][row][col] =
                    (int8_t)alu_requant_relu(conv2_bias_int32[oc], conv2_requant_multiplier);
            }
        }
    }
}

static void run_pool2(const int8_t input[16][10][10], int8_t output[16][5][5]) {
    for (int ch = 0; ch < 16; ch++) {
        for (int row = 0; row < 5; row++) {
            for (int col = 0; col < 5; col++) {
                output[ch][row][col] = (int8_t)alu_pool4(
                    input[ch][row * 2][col * 2],
                    input[ch][row * 2][col * 2 + 1],
                    input[ch][row * 2 + 1][col * 2],
                    input[ch][row * 2 + 1][col * 2 + 1]);
            }
        }
    }
}

static void run_conv3(const int8_t input[16][5][5], int8_t output[120]) {
    ap_uint<32> ignored = 0;
    int act[25];
    int weight[25];

    for (int oc = 0; oc < 120; oc++) {
        alu_clear();
        for (int ic = 0; ic < 16; ic++) {
            int idx = 0;
            for (int kr = 0; kr < 5; kr++) {
                for (int kc = 0; kc < 5; kc++) {
                    act[idx] = input[ic][kr][kc];
                    weight[idx] = conv3_weight_int8[oc][ic][kr][kc];
                    idx++;
                }
            }
            alu_mac_25(act, weight);
        }
        output[oc] = (int8_t)alu_requant_relu(conv3_bias_int32[oc], conv3_requant_multiplier);
    }
}

static void run_fc1(const int8_t input[120], int8_t output[84]) {
    ap_uint<32> ignored = 0;
    int act[25];
    int weight[25];

    for (int oc = 0; oc < 84; oc++) {
        alu_clear();
        for (int base = 0; base < 120; base += 25) {
            for (int i = 0; i < 25; i++) {
                int idx = base + i;
                act[i] = (idx < 120) ? input[idx] : 0;
                weight[i] = (idx < 120) ? fc1_weight_int8[oc][idx] : 0;
            }
            alu_mac_25(act, weight);
        }
        output[oc] = (int8_t)alu_requant_relu(fc1_bias_int32[oc], fc1_requant_multiplier);
    }
}

static void run_fc2(const int8_t input[84], int32_t logits[10]) {
    ap_uint<32> ignored = 0;
    int act[25];
    int weight[25];

    for (int oc = 0; oc < 10; oc++) {
        alu_clear();
        for (int base = 0; base < 84; base += 25) {
            for (int i = 0; i < 25; i++) {
                int idx = base + i;
                act[i] = (idx < 84) ? input[idx] : 0;
                weight[i] = (idx < 84) ? fc2_weight_int8[oc][idx] : 0;
            }
            alu_mac_25(act, weight);
        }
        CNN_ALU_Top((ap_uint<32>)(ap_int<32>)fc2_bias_int32[oc], 0, CMD_ADD_BIAS, &ignored);
        logits[oc] = alu_read();
    }
}

static int argmax10(const int32_t logits[10]) {
    int best = 0;
    for (int i = 1; i < 10; i++) {
        if (logits[i] > logits[best]) {
            best = i;
        }
    }
    return best;
}

static int run_lenet(const int8_t input[32][32], int32_t logits[10]) {
    static int8_t c1[6][28][28];
    static int8_t p1[6][14][14];
    static int8_t c2[16][10][10];
    static int8_t p2[16][5][5];
    static int8_t c3[120];
    static int8_t fc1[84];

    run_conv1(input, c1);
    std::cout << "debug c1=" << (int)c1[0][0][0];
    run_pool1(c1, p1);
    std::cout << " p1=" << (int)p1[0][0][0];
    run_conv2(p1, c2);
    std::cout << " c2=" << (int)c2[0][0][0];
    run_pool2(c2, p2);
    std::cout << " p2=" << (int)p2[0][0][0];
    std::cout << " p2_ch0_0_7=[";
    for (int i = 0; i < 8; i++) {
        if (i) std::cout << ", ";
        std::cout << (int)p2[0][i / 5][i % 5];
    }
    std::cout << "]";
    std::cout << " p2_ch_0_7_00=[";
    for (int i = 0; i < 8; i++) {
        if (i) std::cout << ", ";
        std::cout << (int)p2[i][0][0];
    }
    std::cout << "]";
    run_conv3(p2, c3);
#ifdef DUMP_CONV3_FIXTURE
    dump_conv3_fixture(p2, c3);
    std::cout << "dumped conv3 fixture" << std::endl;
    return 0;
#endif
    std::cout << " c3=" << (int)c3[0];
    std::cout << " c3_0_7=[";
    for (int i = 0; i < 8; i++) {
        if (i) std::cout << ", ";
        std::cout << (int)c3[i];
    }
    std::cout << "]";
    run_fc1(c3, fc1);
    std::cout << " fc1=" << (int)fc1[0] << std::endl;
    std::cout << "debug fc1_0_7=[";
    for (int i = 0; i < 8; i++) {
        if (i) std::cout << ", ";
        std::cout << (int)fc1[i];
    }
    std::cout << "]" << std::endl;
    run_fc2(fc1, logits);
    return argmax10(logits);
}

int main() {
    const char *paths[10] = {
        "mnist_int8_digit0_sample3_32x32.txt",
        "mnist_int8_digit1_sample2_32x32.txt",
        "mnist_int8_digit2_sample1_32x32.txt",
        "mnist_int8_digit3_sample18_32x32.txt",
        "mnist_int8_digit4_sample4_32x32.txt",
        "mnist_int8_digit5_sample8_32x32.txt",
        "mnist_int8_digit6_sample11_32x32.txt",
        "mnist_int8_digit7_sample0_32x32.txt",
        "mnist_int8_digit8_sample61_32x32.txt",
        "mnist_int8_digit9_sample7_32x32.txt",
    };

    int correct = 0;
#ifdef DUMP_CONV3_FIXTURE
    const int first_sample = 7;
    const int last_sample = 8;
#else
    const int first_sample = 0;
    const int last_sample = 10;
#endif
    for (int i = first_sample; i < last_sample; i++) {
        int8_t image[32][32];
        int label = -1;
        int32_t logits[10];

        if (!load_int8_txt(paths[i], image, &label)) {
            std::cout << "Failed to load " << paths[i] << std::endl;
            return 1;
        }

        int pred = run_lenet(image, logits);
        correct += (pred == label) ? 1 : 0;
        std::cout << "sample=" << paths[i]
                  << " label=" << label
                  << " pred=" << pred
                  << " logits=[";
        for (int k = 0; k < 10; k++) {
            if (k != 0) {
                std::cout << ", ";
            }
            std::cout << logits[k];
        }
        std::cout << "]" << std::endl;
    }

    std::cout << "0_to_9_sample_accuracy=" << correct << "/10" << std::endl;
    return (correct == 10) ? 0 : 1;
}
