#include <stdint.h>
#include "../../sw/output/weights.h"

// Software multiplication routine for RV32I which has no hardware multiplier
int32_t __mulsi3(int32_t a, int32_t b) {
    int32_t res = 0;
    uint32_t u_b = (uint32_t)b;
    while (u_b > 0) {
        if (u_b & 1) {
            res += a;
        }
        a <<= 1;
        u_b >>= 1;
    }
    return res;
}

// Struct to guarantee layout order in BRAM (starting at 0x00008000)
struct status_block {
    volatile uint32_t status;
    volatile uint32_t predicted_label_out;
    volatile int32_t class_scores_out[10];
};

volatile struct status_block s_block __attribute__((section(".status_section"))) = {
    .status = 0xAA55AA55,
    .predicted_label_out = 999,
    .class_scores_out = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
};

// Pure C Software Emulator for MAC4 (performs emulated multiplication since RV32I has no MUL)
int32_t sw_mac4(uint32_t rs1, uint32_t rs2) {
    int32_t sum = 0;
    for (int i = 0; i < 4; i++) {
        uint8_t val = (rs1 >> (i * 8)) & 0xFF;
        int8_t weight = (int8_t)((rs2 >> (i * 8)) & 0xFF);
        sum += (int32_t)val * (int32_t)weight;
    }
    return sum;
}

// Pure C Software Emulator for MaxPool2
uint8_t sw_maxpool2(uint8_t a, uint8_t b, uint8_t c, uint8_t d) {
    uint8_t max = a;
    if (b > max) max = b;
    if (c > max) max = c;
    if (d > max) max = d;
    return max;
}

// Pure C Software Emulator for Rescale & ReLU
uint8_t sw_rescale(int32_t acc, int32_t shift) {
    int32_t rounding = (shift != 0) ? (1 << (shift - 1)) : 0;
    int32_t rounded = acc + rounding;
    int32_t shifted = rounded >> shift; // Arithmetic right shift
    if (shifted < 0) return 0;
    if (shifted > 255) return 255;
    return (uint8_t)shifted;
}

// Input image (MNIST Image 0, Label = 7)
const uint8_t img0[784] = {
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 84, 185, 159, 151, 60, 36, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 222, 254, 254, 254, 254, 241, 198, 198, 198, 198, 198, 198, 198, 198, 170, 52, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 67, 114, 72, 114, 163, 227, 254, 225, 254, 254, 254, 250, 229, 254, 254, 140, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 66, 14, 67, 67, 67, 59, 21, 236, 254, 106, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 83, 253, 209, 18, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 233, 255, 83, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 129, 254, 238, 44, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 249, 254, 62, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 133, 254, 187, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 205, 248, 58, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 126, 254, 182, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 75, 251, 240, 57, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 19, 221, 254, 166, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 203, 254, 219, 35, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 38, 254, 254, 77, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 31, 224, 254, 115, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 133, 254, 254, 52, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 61, 242, 254, 254, 52, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 121, 254, 254, 219, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 121, 254, 207, 18, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

// Padded weights in RAM (built at runtime)
int8_t conv1_w_padded[6][28];
int8_t conv2_w_padded[16][152];

// Intermediate buffers
uint8_t conv1_out[24][24][6];
uint8_t pool1_out[12][12][6];
uint8_t conv2_out[8][8][16];
uint8_t pool2_out[4][4][16];
uint8_t fc1_out[120];
uint8_t fc2_out[84];
int32_t fc3_out[10];

void prepare_weights() {
    for (int oc = 0; oc < 6; oc++) {
        for (int i = 0; i < 25; i++) {
            conv1_w_padded[oc][i] = conv1_w[oc * 25 + i];
        }
        conv1_w_padded[oc][25] = 0;
        conv1_w_padded[oc][26] = 0;
        conv1_w_padded[oc][27] = 0;
    }

    for (int oc = 0; oc < 16; oc++) {
        for (int i = 0; i < 150; i++) {
            conv2_w_padded[oc][i] = conv2_w[oc * 150 + i];
        }
        conv2_w_padded[oc][150] = 0;
        conv2_w_padded[oc][151] = 0;
    }
}

int main() {
    prepare_weights();

    // 1. CONV1
    uint8_t conv1_window[28];
    conv1_window[25] = 0;
    conv1_window[26] = 0;
    conv1_window[27] = 0;

    for (int oc = 0; oc < 6; oc++) {
        uint32_t w0 = *(uint32_t*)&conv1_w_padded[oc][0];
        uint32_t w1 = *(uint32_t*)&conv1_w_padded[oc][4];
        uint32_t w2 = *(uint32_t*)&conv1_w_padded[oc][8];
        uint32_t w3 = *(uint32_t*)&conv1_w_padded[oc][12];
        uint32_t w4 = *(uint32_t*)&conv1_w_padded[oc][16];
        uint32_t w5 = *(uint32_t*)&conv1_w_padded[oc][20];
        uint32_t w6 = *(uint32_t*)&conv1_w_padded[oc][24];

        int32_t bias = conv1_b[oc];

        for (int oh = 0; oh < 24; oh++) {
            for (int ow = 0; ow < 24; ow++) {
                for (int ky = 0; ky < 5; ky++) {
                    int r = oh + ky;
                    int c = ow;
                    conv1_window[ky * 5 + 0] = img0[r * 28 + c + 0];
                    conv1_window[ky * 5 + 1] = img0[r * 28 + c + 1];
                    conv1_window[ky * 5 + 2] = img0[r * 28 + c + 2];
                    conv1_window[ky * 5 + 3] = img0[r * 28 + c + 3];
                    conv1_window[ky * 5 + 4] = img0[r * 28 + c + 4];
                }

                uint32_t x0 = *(uint32_t*)&conv1_window[0];
                uint32_t x1 = *(uint32_t*)&conv1_window[4];
                uint32_t x2 = *(uint32_t*)&conv1_window[8];
                uint32_t x3 = *(uint32_t*)&conv1_window[12];
                uint32_t x4 = *(uint32_t*)&conv1_window[16];
                uint32_t x5 = *(uint32_t*)&conv1_window[20];
                uint32_t x6 = *(uint32_t*)&conv1_window[24];

                int32_t acc = bias;
                acc += sw_mac4(x0, w0);
                acc += sw_mac4(x1, w1);
                acc += sw_mac4(x2, w2);
                acc += sw_mac4(x3, w3);
                acc += sw_mac4(x4, w4);
                acc += sw_mac4(x5, w5);
                acc += sw_mac4(x6, w6);

                conv1_out[oh][ow][oc] = sw_rescale(acc, CONV1_SHIFT);
            }
        }
    }

    // 2. POOL1
    for (int ic = 0; ic < 6; ic++) {
        for (int oh = 0; oh < 12; oh++) {
            for (int ow = 0; ow < 12; ow++) {
                uint8_t a = conv1_out[2 * oh + 0][2 * ow + 0][ic];
                uint8_t b = conv1_out[2 * oh + 0][2 * ow + 1][ic];
                uint8_t c = conv1_out[2 * oh + 1][2 * ow + 0][ic];
                uint8_t d = conv1_out[2 * oh + 1][2 * ow + 1][ic];

                pool1_out[oh][ow][ic] = sw_maxpool2(a, b, c, d);
            }
        }
    }

    // 3. CONV2
    uint8_t conv2_window[152];
    conv2_window[150] = 0;
    conv2_window[151] = 0;

    for (int oc = 0; oc < 16; oc++) {
        int32_t bias = conv2_b[oc];

        for (int oh = 0; oh < 8; oh++) {
            for (int ow = 0; ow < 8; ow++) {
                int ptr = 0;
                for (int ic = 0; ic < 6; ic++) {
                    for (int ky = 0; ky < 5; ky++) {
                        int r = oh + ky;
                        int c = ow;
                        conv2_window[ptr++] = pool1_out[r][c + 0][ic];
                        conv2_window[ptr++] = pool1_out[r][c + 1][ic];
                        conv2_window[ptr++] = pool1_out[r][c + 2][ic];
                        conv2_window[ptr++] = pool1_out[r][c + 3][ic];
                        conv2_window[ptr++] = pool1_out[r][c + 4][ic];
                    }
                }

                int32_t acc = bias;
                uint32_t *x_ptr = (uint32_t*)conv2_window;
                uint32_t *w_ptr = (uint32_t*)&conv2_w_padded[oc][0];

                for (int i = 0; i < 38; i++) {
                    acc += sw_mac4(x_ptr[i], w_ptr[i]);
                }

                conv2_out[oh][ow][oc] = sw_rescale(acc, CONV2_SHIFT);
            }
        }
    }

    // 4. POOL2
    for (int ic = 0; ic < 16; ic++) {
        for (int oh = 0; oh < 4; oh++) {
            for (int ow = 0; ow < 4; ow++) {
                uint8_t a = conv2_out[2 * oh + 0][2 * ow + 0][ic];
                uint8_t b = conv2_out[2 * oh + 0][2 * ow + 1][ic];
                uint8_t c = conv2_out[2 * oh + 1][2 * ow + 0][ic];
                uint8_t d = conv2_out[2 * oh + 1][2 * ow + 1][ic];

                pool2_out[oh][ow][ic] = sw_maxpool2(a, b, c, d);
            }
        }
    }

    // Flatten pool2_out (4x4x16 = 256 bytes)
    uint8_t pool2_flat[256];
    int flat_ptr = 0;
    for (int ic = 0; ic < 16; ic++) {
        for (int ih = 0; ih < 4; ih++) {
            for (int iw = 0; iw < 4; iw++) {
                pool2_flat[flat_ptr++] = pool2_out[ih][iw][ic];
            }
        }
    }

    // 5. FC1 (Linear 256 -> 120)
    for (int oc = 0; oc < 120; oc++) {
        int32_t bias = fc1_b[oc];
        uint32_t *x_ptr = (uint32_t*)pool2_flat;
        uint32_t *w_ptr = (uint32_t*)&fc1_w[oc * 256];

        int32_t acc = bias;
        for (int i = 0; i < 64; i++) {
            acc += sw_mac4(x_ptr[i], w_ptr[i]);
        }

        fc1_out[oc] = sw_rescale(acc, FC1_SHIFT);
    }

    // 6. FC2 (Linear 120 -> 84)
    for (int oc = 0; oc < 84; oc++) {
        int32_t bias = fc2_b[oc];
        uint32_t *x_ptr = (uint32_t*)fc1_out;
        uint32_t *w_ptr = (uint32_t*)&fc2_w[oc * 120];

        int32_t acc = bias;
        for (int i = 0; i < 30; i++) {
            acc += sw_mac4(x_ptr[i], w_ptr[i]);
        }

        fc2_out[oc] = sw_rescale(acc, FC2_SHIFT);
    }

    // 7. FC3 (Linear 84 -> 10)
    for (int oc = 0; oc < 10; oc++) {
        int32_t bias = fc3_b[oc];
        uint32_t *x_ptr = (uint32_t*)fc2_out;
        uint32_t *w_ptr = (uint32_t*)&fc3_w[oc * 84];

        int32_t acc = bias;
        for (int i = 0; i < 21; i++) {
            acc += sw_mac4(x_ptr[i], w_ptr[i]);
        }

        fc3_out[oc] = acc;
        s_block.class_scores_out[oc] = acc;
    }

    // 8. Argmax
    int predicted_label = 0;
    int32_t max_score = fc3_out[0];

    for (int i = 1; i < 10; i++) {
        if (fc3_out[i] > max_score) {
            max_score = fc3_out[i];
            predicted_label = i;
        }
    }

    s_block.predicted_label_out = predicted_label;

    if (predicted_label == 7) {
        s_block.status = 0x12345678; // SUCCESS
    } else {
        s_block.status = 0xDEADBEEF; // FAILURE
    }

    return 0;
}
