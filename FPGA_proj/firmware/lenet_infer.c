#include "cnn_alu_custom_ops.h"
#include "lenet_mem_map.h"
#include "../mem/lenet_param_addr.h"

#include <stdint.h>

static int32_t c1[6][28][28];
static int32_t p1[6][14][14];
static int32_t c2[16][10][10];
static int32_t p2[16][5][5];
static int32_t c3[120];
static int32_t fc1[84];
static int32_t logits[10];

static inline int8_t load_i8(uint32_t addr)
{
    return *(volatile int8_t *)addr;
}

static inline int32_t load_i32(uint32_t addr)
{
    return *(volatile int32_t *)addr;
}

static inline void store_i32(uint32_t addr, int32_t value)
{
    *(volatile int32_t *)addr = value;
}

static inline void alu_load_pack4(int load_weights, uint32_t packed)
{
    if (load_weights)
        cnn_load_w_pack4(packed);
    else
        cnn_load_a_pack4(packed);
}

static inline __attribute__((always_inline)) void alu_load_25(int load_weights, const int8_t values[25])
{
    alu_load_pack4(load_weights, cnn_pack4(values[0],  values[1],  values[2],  values[3]));
    alu_load_pack4(load_weights, cnn_pack4(values[4],  values[5],  values[6],  values[7]));
    alu_load_pack4(load_weights, cnn_pack4(values[8],  values[9],  values[10], values[11]));
    alu_load_pack4(load_weights, cnn_pack4(values[12], values[13], values[14], values[15]));
    alu_load_pack4(load_weights, cnn_pack4(values[16], values[17], values[18], values[19]));
    alu_load_pack4(load_weights, cnn_pack4(values[20], values[21], values[22], values[23]));
    alu_load_pack4(load_weights, cnn_pack4(values[24], 0, 0, 0));
}

static inline __attribute__((always_inline)) void alu_mac_25(const int8_t act[25], const int8_t weight[25])
{
    cnn_mac_pack4(cnn_pack4(act[0],  act[1],  act[2],  act[3]),
                  cnn_pack4(weight[0],  weight[1],  weight[2],  weight[3]));
    cnn_mac_pack4(cnn_pack4(act[4],  act[5],  act[6],  act[7]),
                  cnn_pack4(weight[4],  weight[5],  weight[6],  weight[7]));
    cnn_mac_pack4(cnn_pack4(act[8],  act[9],  act[10], act[11]),
                  cnn_pack4(weight[8],  weight[9],  weight[10], weight[11]));
    cnn_mac_pack4(cnn_pack4(act[12], act[13], act[14], act[15]),
                  cnn_pack4(weight[12], weight[13], weight[14], weight[15]));
    cnn_mac_pack4(cnn_pack4(act[16], act[17], act[18], act[19]),
                  cnn_pack4(weight[16], weight[17], weight[18], weight[19]));
    cnn_mac_pack4(cnn_pack4(act[20], act[21], act[22], act[23]),
                  cnn_pack4(weight[20], weight[21], weight[22], weight[23]));
    cnn_mac_pack4(cnn_pack4(act[24], 0, 0, 0),
                  cnn_pack4(weight[24], 0, 0, 0));
}

static int8_t alu_requant_relu(int32_t bias, int32_t multiplier)
{
    return (int8_t)cnn_bias_requant_relu_read(bias, multiplier);
}

static int8_t alu_pool4(int8_t a0, int8_t a1, int8_t a2, int8_t a3)
{
    return (int8_t)cnn_pool4_read(cnn_pack4(a0, a1, a2, a3));
}

static int8_t input_pixel(int row, int col)
{
    return load_i8(LENET_INPUT_BASE_ADDR + (uint32_t)(row * 32 + col));
}

static int8_t conv1_w(int oc, int kr, int kc)
{
    uint32_t idx = (uint32_t)(((oc * 1 + 0) * 5 + kr) * 5 + kc);
    return load_i8(CONV1_WEIGHT_INT8_ADDR + idx);
}

static int8_t conv2_w(int oc, int ic, int kr, int kc)
{
    uint32_t idx = (uint32_t)(((oc * 6 + ic) * 5 + kr) * 5 + kc);
    return load_i8(CONV2_WEIGHT_INT8_ADDR + idx);
}

static int8_t conv3_w(int oc, int ic, int kr, int kc)
{
    uint32_t idx = (uint32_t)(((oc * 16 + ic) * 5 + kr) * 5 + kc);
    return load_i8(CONV3_WEIGHT_INT8_ADDR + idx);
}

static int8_t fc1_w(int oc, int idx)
{
    return load_i8(FC1_WEIGHT_INT8_ADDR + (uint32_t)(oc * 120 + idx));
}

static int8_t fc2_w(int oc, int idx)
{
    return load_i8(FC2_WEIGHT_INT8_ADDR + (uint32_t)(oc * 84 + idx));
}

static void run_conv1(void)
{
    int8_t act[25];
    int8_t weight[25];
    int32_t mult = load_i32(CONV1_REQUANT_MULTIPLIER_ADDR);

    for (int oc = 0; oc < 6; oc++) {
        int32_t bias = load_i32(CONV1_BIAS_INT32_ADDR + (uint32_t)(oc * 4));
        for (int row = 0; row < 28; row++) {
            for (int col = 0; col < 28; col++) {
                int idx = 0;
                for (int kr = 0; kr < 5; kr++) {
                    for (int kc = 0; kc < 5; kc++) {
                        act[idx] = input_pixel(row + kr, col + kc);
                        weight[idx] = conv1_w(oc, kr, kc);
                        idx++;
                    }
                }

                cnn_clear_acc();
                alu_mac_25(act, weight);
                c1[oc][row][col] = alu_requant_relu(bias, mult);
            }
        }
    }
}

static void run_pool1(void)
{
    for (int ch = 0; ch < 6; ch++) {
        for (int row = 0; row < 14; row++) {
            for (int col = 0; col < 14; col++) {
                p1[ch][row][col] = alu_pool4(
                    (int8_t)c1[ch][row * 2][col * 2],
                    (int8_t)c1[ch][row * 2][col * 2 + 1],
                    (int8_t)c1[ch][row * 2 + 1][col * 2],
                    (int8_t)c1[ch][row * 2 + 1][col * 2 + 1]);
            }
        }
    }
}

static void run_conv2(void)
{
    int8_t act[25];
    int8_t weight[25];
    int32_t mult = load_i32(CONV2_REQUANT_MULTIPLIER_ADDR);

    for (int oc = 0; oc < 16; oc++) {
        int32_t bias = load_i32(CONV2_BIAS_INT32_ADDR + (uint32_t)(oc * 4));
        for (int row = 0; row < 10; row++) {
            for (int col = 0; col < 10; col++) {
                cnn_clear_acc();
                for (int ic = 0; ic < 6; ic++) {
                    int idx = 0;
                    for (int kr = 0; kr < 5; kr++) {
                        for (int kc = 0; kc < 5; kc++) {
                            act[idx] = (int8_t)p1[ic][row + kr][col + kc];
                            weight[idx] = conv2_w(oc, ic, kr, kc);
                            idx++;
                        }
                    }
                    alu_mac_25(act, weight);
                }
                c2[oc][row][col] = alu_requant_relu(bias, mult);
            }
        }
    }
}

static void run_pool2(void)
{
    for (int ch = 0; ch < 16; ch++) {
        for (int row = 0; row < 5; row++) {
            for (int col = 0; col < 5; col++) {
                p2[ch][row][col] = alu_pool4(
                    (int8_t)c2[ch][row * 2][col * 2],
                    (int8_t)c2[ch][row * 2][col * 2 + 1],
                    (int8_t)c2[ch][row * 2 + 1][col * 2],
                    (int8_t)c2[ch][row * 2 + 1][col * 2 + 1]);
            }
        }
    }
}

static void run_conv3(void)
{
    int8_t act[25];
    int8_t weight[25];
    int32_t mult = load_i32(CONV3_REQUANT_MULTIPLIER_ADDR);

    for (int oc = 0; oc < 120; oc++) {
        int32_t bias = load_i32(CONV3_BIAS_INT32_ADDR + (uint32_t)(oc * 4));
        cnn_clear_acc();
        for (int ic = 0; ic < 16; ic++) {
            int idx = 0;
            for (int kr = 0; kr < 5; kr++) {
                for (int kc = 0; kc < 5; kc++) {
                    act[idx] = (int8_t)p2[ic][kr][kc];
                    weight[idx] = conv3_w(oc, ic, kr, kc);
                    idx++;
                }
            }
            alu_mac_25(act, weight);
        }
        c3[oc] = alu_requant_relu(bias, mult);
    }
}

static void run_fc1(void)
{
    int8_t act[25];
    int8_t weight[25];
    int32_t mult = load_i32(FC1_REQUANT_MULTIPLIER_ADDR);

    for (int oc = 0; oc < 84; oc++) {
        int32_t bias = load_i32(FC1_BIAS_INT32_ADDR + (uint32_t)(oc * 4));
        cnn_clear_acc();
        for (int base = 0; base < 120; base += 25) {
            for (int i = 0; i < 25; i++) {
                int idx = base + i;
                act[i] = (idx < 120) ? (int8_t)c3[idx] : 0;
                weight[i] = (idx < 120) ? fc1_w(oc, idx) : 0;
            }
            alu_mac_25(act, weight);
        }
        fc1[oc] = alu_requant_relu(bias, mult);
    }
}

static void run_fc2(void)
{
    int8_t act[25];
    int8_t weight[25];

    for (int oc = 0; oc < 10; oc++) {
        int32_t bias = load_i32(FC2_BIAS_INT32_ADDR + (uint32_t)(oc * 4));
        cnn_clear_acc();
        for (int base = 0; base < 84; base += 25) {
            for (int i = 0; i < 25; i++) {
                int idx = base + i;
                act[i] = (idx < 84) ? (int8_t)fc1[idx] : 0;
                weight[i] = (idx < 84) ? fc2_w(oc, idx) : 0;
            }
            alu_mac_25(act, weight);
        }
        cnn_add_bias(bias);
        logits[oc] = (int32_t)cnn_get_res();
    }
}

static int argmax10(void)
{
    int best = 0;
    for (int i = 1; i < 10; i++) {
        if (logits[i] > logits[best]) {
            best = i;
        }
    }
    return best;
}

void main(void)
{
    run_conv1();
    store_i32(LENET_DEBUG_ADDR + 0u, c1[0][0][0]);
    run_pool1();
    store_i32(LENET_DEBUG_ADDR + 4u, p1[0][0][0]);
    run_conv2();
    store_i32(LENET_DEBUG_ADDR + 8u, c2[0][0][0]);
    run_pool2();
    store_i32(LENET_DEBUG_ADDR + 12u, p2[0][0][0]);
    store_i32(LENET_DEBUG_ADDR + 96u, p2[0][0][0]);
    store_i32(LENET_DEBUG_ADDR + 100u, p2[0][0][1]);
    store_i32(LENET_DEBUG_ADDR + 104u, p2[0][0][2]);
    store_i32(LENET_DEBUG_ADDR + 108u, p2[0][0][3]);
    store_i32(LENET_DEBUG_ADDR + 112u, p2[0][0][4]);
    store_i32(LENET_DEBUG_ADDR + 116u, p2[0][1][0]);
    store_i32(LENET_DEBUG_ADDR + 120u, p2[0][1][1]);
    store_i32(LENET_DEBUG_ADDR + 124u, p2[0][1][2]);
    for (int i = 0; i < 8; i++) {
        store_i32(LENET_DEBUG_ADDR + 128u + (uint32_t)(i * 4), p2[i][0][0]);
    }
    run_conv3();
    store_i32(LENET_DEBUG_ADDR + 16u, c3[0]);
    for (int i = 0; i < 8; i++) {
        store_i32(LENET_DEBUG_ADDR + 32u + (uint32_t)(i * 4), c3[i]);
    }
    run_fc1();
    store_i32(LENET_DEBUG_ADDR + 20u, fc1[0]);
    for (int i = 0; i < 8; i++) {
        store_i32(LENET_DEBUG_ADDR + 64u + (uint32_t)(i * 4), fc1[i]);
    }
    run_fc2();

    int pred = argmax10();
    store_i32(LENET_RESULT_ADDR, pred);
    store_i32(LENET_RESULT_ADDR + 4u, load_i32(LENET_EXPECTED_ADDR));
    for (int i = 0; i < 10; i++) {
        store_i32(LENET_RESULT_ADDR + 8u + (uint32_t)(i * 4), logits[i]);
    }
    store_i32(LENET_DONE_ADDR, 1);

    while (1) {
    }
}
