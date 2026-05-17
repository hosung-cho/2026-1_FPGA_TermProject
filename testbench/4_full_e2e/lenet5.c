#include <stdint.h>
#include "../../sw/output/weights.h"

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

// CFU Instruction Macros
#define cfu_mac4(rs1, rs2) \
    ({ \
        uint32_t rd; \
        asm volatile(".insn r 0x0b, 0, 0, %0, %1, %2" : "=r"(rd) : "r"(rs1), "r"(rs2)); \
        rd; \
    })

#define cfu_maxpool2(rs1, rs2) \
    ({ \
        uint32_t rd; \
        asm volatile(".insn r 0x0b, 0, 2, %0, %1, %2" : "=r"(rd) : "r"(rs1), "r"(rs2)); \
        rd; \
    })

#define cfu_rescale(rs1, rs2) \
    ({ \
        uint32_t rd; \
        asm volatile(".insn r 0x0b, 0, 4, %0, %1, %2" : "=r"(rd) : "r"(rs1), "r"(rs2)); \
        rd; \
    })

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

// Copy and pad weights to 4-byte multiples for CFU instruction
void prepare_weights() {
    // conv1: 6 filters of 5x5=25 bytes -> pad to 28 bytes per filter
    for (int oc = 0; oc < 6; oc++) {
        for (int i = 0; i < 25; i++) {
            conv1_w_padded[oc][i] = conv1_w[oc * 25 + i];
        }
        conv1_w_padded[oc][25] = 0;
        conv1_w_padded[oc][26] = 0;
        conv1_w_padded[oc][27] = 0;
    }

    // conv2: 16 filters of 6x5x5=150 bytes -> pad to 152 bytes per filter
    for (int oc = 0; oc < 16; oc++) {
        for (int i = 0; i < 150; i++) {
            conv2_w_padded[oc][i] = conv2_w[oc * 150 + i];
        }
        conv2_w_padded[oc][150] = 0;
        conv2_w_padded[oc][151] = 0;
    }
}

int main() {
    // 0. Runtime weights padding initialization
    prepare_weights();

    // 1. CONV1
    // Input: img0 (28x28), Output: conv1_out (24x24x6)
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
                // Extract 25 pixels
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
                acc += (int32_t)cfu_mac4(x0, w0);
                acc += (int32_t)cfu_mac4(x1, w1);
                acc += (int32_t)cfu_mac4(x2, w2);
                acc += (int32_t)cfu_mac4(x3, w3);
                acc += (int32_t)cfu_mac4(x4, w4);
                acc += (int32_t)cfu_mac4(x5, w5);
                acc += (int32_t)cfu_mac4(x6, w6);

                // Rescale will automatically ReLU clamp
                conv1_out[oh][ow][oc] = (uint8_t)cfu_rescale(acc, CONV1_SHIFT);
            }
        }
    }

    // 2. POOL1
    // Input: conv1_out (24x24x6), Output: pool1_out (12x12x6)
    for (int ic = 0; ic < 6; ic++) {
        for (int oh = 0; oh < 12; oh++) {
            for (int ow = 0; ow < 12; ow++) {
                uint8_t a = conv1_out[2 * oh + 0][2 * ow + 0][ic];
                uint8_t b = conv1_out[2 * oh + 0][2 * ow + 1][ic];
                uint8_t c = conv1_out[2 * oh + 1][2 * ow + 0][ic];
                uint8_t d = conv1_out[2 * oh + 1][2 * ow + 1][ic];

                uint32_t rs1 = (b << 8) | a;
                uint32_t rs2 = (d << 8) | c;
                pool1_out[oh][ow][ic] = (uint8_t)cfu_maxpool2(rs1, rs2);
            }
        }
    }

    // 3. CONV2
    // Input: pool1_out (12x12x6), Output: conv2_out (8x8x16)
    uint8_t conv2_window[152];
    conv2_window[150] = 0;
    conv2_window[151] = 0;

    for (int oc = 0; oc < 16; oc++) {
        int32_t bias = conv2_b[oc];

        for (int oh = 0; oh < 8; oh++) {
            for (int ow = 0; ow < 8; ow++) {
                // Extract 150 pixels across 6 channels
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

                // Perform 38 cfu_mac4 iterations using pointers
                int32_t acc = bias;
                uint32_t *x_ptr = (uint32_t*)conv2_window;
                uint32_t *w_ptr = (uint32_t*)&conv2_w_padded[oc][0];

                for (int i = 0; i < 38; i++) {
                    acc += (int32_t)cfu_mac4(x_ptr[i], w_ptr[i]);
                }

                // Rescale will automatically ReLU clamp
                conv2_out[oh][ow][oc] = (uint8_t)cfu_rescale(acc, CONV2_SHIFT);
            }
        }
    }

    // 4. POOL2
    // Input: conv2_out (8x8x16), Output: pool2_out (4x4x16)
    for (int ic = 0; ic < 16; ic++) {
        for (int oh = 0; oh < 4; oh++) {
            for (int ow = 0; ow < 4; ow++) {
                uint8_t a = conv2_out[2 * oh + 0][2 * ow + 0][ic];
                uint8_t b = conv2_out[2 * oh + 0][2 * ow + 1][ic];
                uint8_t c = conv2_out[2 * oh + 1][2 * ow + 0][ic];
                uint8_t d = conv2_out[2 * oh + 1][2 * ow + 1][ic];

                uint32_t rs1 = (b << 8) | a;
                uint32_t rs2 = (d << 8) | c;
                pool2_out[oh][ow][ic] = (uint8_t)cfu_maxpool2(rs1, rs2);
            }
        }
    }

    // Flatten pool2_out (4x4x16 = 256 bytes)
    // Flatten layout: [C][H][W] to match fc1 weight exporter layout
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
    // Weights shape: (120, 256), already contiguous multiple of 4
    for (int oc = 0; oc < 120; oc++) {
        int32_t bias = fc1_b[oc];
        uint32_t *x_ptr = (uint32_t*)pool2_flat;
        uint32_t *w_ptr = (uint32_t*)&fc1_w[oc * 256];

        int32_t acc = bias;
        for (int i = 0; i < 64; i++) {
            acc += (int32_t)cfu_mac4(x_ptr[i], w_ptr[i]);
        }

        // Rescale automatically ReLU clamps
        fc1_out[oc] = (uint8_t)cfu_rescale(acc, FC1_SHIFT);
    }

    // 6. FC2 (Linear 120 -> 84)
    // Weights shape: (84, 120), already contiguous multiple of 4
    for (int oc = 0; oc < 84; oc++) {
        int32_t bias = fc2_b[oc];
        uint32_t *x_ptr = (uint32_t*)fc1_out;
        uint32_t *w_ptr = (uint32_t*)&fc2_w[oc * 120];

        int32_t acc = bias;
        for (int i = 0; i < 30; i++) {
            acc += (int32_t)cfu_mac4(x_ptr[i], w_ptr[i]);
        }

        // Rescale automatically ReLU clamps
        fc2_out[oc] = (uint8_t)cfu_rescale(acc, FC2_SHIFT);
    }

    // 7. FC3 (Linear 84 -> 10)
    // Weights shape: (10, 84), already contiguous multiple of 4
    for (int oc = 0; oc < 10; oc++) {
        int32_t bias = fc3_b[oc];
        uint32_t *x_ptr = (uint32_t*)fc2_out;
        uint32_t *w_ptr = (uint32_t*)&fc3_w[oc * 84];

        int32_t acc = bias;
        for (int i = 0; i < 21; i++) {
            acc += (int32_t)cfu_mac4(x_ptr[i], w_ptr[i]);
        }

        // Raw output scores (no ReLU or scale)
        fc3_out[oc] = acc;
        s_block.class_scores_out[oc] = acc; // Export for debug
    }

    // 8. Argmax calculation
    int predicted_label = 0;
    int32_t max_score = fc3_out[0];

    for (int i = 1; i < 10; i++) {
        if (fc3_out[i] > max_score) {
            max_score = fc3_out[i];
            predicted_label = i;
        }
    }

    s_block.predicted_label_out = predicted_label; // Export for debug

    // MNIST Image 0's actual label is 7
    if (predicted_label == 7) {
        s_block.status = 0x12345678; // SUCCESS
    } else {
        s_block.status = 0xDEADBEEF; // FAILURE
    }

    return 0;
}
