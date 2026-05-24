#ifndef CNN_ALU_CUSTOM_OPS_H
#define CNN_ALU_CUSTOM_OPS_H

#include <stdint.h>

#ifdef CNN_ALU_DISABLE

#define REQUANT_SHIFT 20

static int32_t sw_cnn_acc_reg;

static inline int8_t sw_lane0(uint32_t packed)
{
    return (int8_t)(uint8_t)(packed & 0xffu);
}

static inline int8_t sw_lane1(uint32_t packed)
{
    return (int8_t)(uint8_t)((packed >> 8) & 0xffu);
}

static inline int8_t sw_lane2(uint32_t packed)
{
    return (int8_t)(uint8_t)((packed >> 16) & 0xffu);
}

static inline int8_t sw_lane3(uint32_t packed)
{
    return (int8_t)(uint8_t)((packed >> 24) & 0xffu);
}

static inline uint32_t cnn_pack4(int8_t b0, int8_t b1, int8_t b2, int8_t b3)
{
    return ((uint32_t)(uint8_t)b0) |
           ((uint32_t)(uint8_t)b1 << 8) |
           ((uint32_t)(uint8_t)b2 << 16) |
           ((uint32_t)(uint8_t)b3 << 24);
}

static inline uint32_t cnn_get_res(void)
{
    return (uint32_t)sw_cnn_acc_reg;
}

static inline void cnn_clear_acc(void)
{
    sw_cnn_acc_reg = 0;
}

static inline void cnn_mac_pack4(uint32_t act_packed, uint32_t weight_packed)
{
    sw_cnn_acc_reg += (int32_t)sw_lane0(act_packed) * (int32_t)sw_lane0(weight_packed);
    sw_cnn_acc_reg += (int32_t)sw_lane1(act_packed) * (int32_t)sw_lane1(weight_packed);
    sw_cnn_acc_reg += (int32_t)sw_lane2(act_packed) * (int32_t)sw_lane2(weight_packed);
    sw_cnn_acc_reg += (int32_t)sw_lane3(act_packed) * (int32_t)sw_lane3(weight_packed);
}

static inline uint32_t cnn_pool4_read(uint32_t act_packed)
{
    int8_t a0 = sw_lane0(act_packed);
    int8_t a1 = sw_lane1(act_packed);
    int8_t a2 = sw_lane2(act_packed);
    int8_t a3 = sw_lane3(act_packed);
    int8_t max1 = (a0 > a1) ? a0 : a1;
    int8_t max2 = (a2 > a3) ? a2 : a3;
    sw_cnn_acc_reg = (max1 > max2) ? max1 : max2;
    return (uint32_t)sw_cnn_acc_reg;
}

static inline int32_t sw_requant_relu(int32_t acc, int32_t multiplier)
{
    if (acc <= 0) {
        return 0;
    }

    int64_t product = (int64_t)acc * (int64_t)multiplier;
    int64_t rounded = product + ((int64_t)1 << (REQUANT_SHIFT - 1));
    int32_t scaled = (int32_t)(rounded >> REQUANT_SHIFT);

    if (scaled > 127) {
        return 127;
    }

    return scaled;
}

static inline uint32_t cnn_bias_requant_relu_read(int32_t bias, int32_t multiplier)
{
    sw_cnn_acc_reg = sw_requant_relu(sw_cnn_acc_reg + bias, multiplier);
    return (uint32_t)sw_cnn_acc_reg;
}

static inline void cnn_add_bias(int32_t bias)
{
    sw_cnn_acc_reg += bias;
}

static inline void cnn_load_w_pack4(uint32_t packed) { (void)packed; }
static inline void cnn_load_a_pack4(uint32_t packed) { (void)packed; }
static inline void cnn_start_mac(void) {}
static inline void cnn_start_pool(void) {}
static inline void cnn_acc_mac(void) {}
static inline void cnn_apply_relu(void)
{
    if (sw_cnn_acc_reg < 0) {
        sw_cnn_acc_reg = 0;
    }
}
static inline void cnn_requant_relu(int32_t multiplier)
{
    sw_cnn_acc_reg = sw_requant_relu(sw_cnn_acc_reg, multiplier);
}

#else

#define CNN_ALU_READ_INSN(funct3, funct7, value)                       \
    ({                                                                 \
        uint32_t in = (uint32_t)(value);                               \
        uint32_t out;                                                  \
        asm volatile ("nop\n\t"                                      \
                      ".insn r 0x0b, " #funct3 ", " #funct7          \
                      ", %0, %1, x0"                                  \
                      : "=r"(out) : "r"(in) : "memory");             \
        out;                                                           \
    })

#define CNN_ALU_VOID_INSN(funct3, funct7, value)                       \
    do {                                                               \
        uint32_t in = (uint32_t)(value);                               \
        asm volatile ("nop\n\t"                                      \
                      ".insn r 0x0b, " #funct3 ", " #funct7          \
                      ", x0, %0, x0"                                  \
                      :: "r"(in) : "memory");                        \
    } while (0)

#define CNN_ALU_VOID2_INSN(funct3, funct7, value1, value2)             \
    do {                                                               \
        uint32_t in1 = (uint32_t)(value1);                             \
        uint32_t in2 = (uint32_t)(value2);                             \
        asm volatile ("nop\n\t"                                      \
                      ".insn r 0x0b, " #funct3 ", " #funct7          \
                      ", x0, %0, %1"                                  \
                      :: "r"(in1), "r"(in2) : "memory");             \
    } while (0)

#define CNN_ALU_READ2_INSN(funct3, funct7, value1, value2)             \
    ({                                                                 \
        uint32_t in1 = (uint32_t)(value1);                             \
        uint32_t in2 = (uint32_t)(value2);                             \
        uint32_t out;                                                  \
        asm volatile ("nop\n\t"                                      \
                      ".insn r 0x0b, " #funct3 ", " #funct7          \
                      ", %0, %1, %2"                                  \
                      : "=r"(out) : "r"(in1), "r"(in2) : "memory"); \
        out;                                                           \
    })

static inline uint32_t cnn_get_res(void)
{
    return CNN_ALU_READ_INSN(3, 0, 0);
}

static inline void cnn_load_w_pack4(uint32_t packed)
{
    CNN_ALU_VOID_INSN(0, 0, packed);
}

static inline void cnn_load_a_pack4(uint32_t packed)
{
    CNN_ALU_VOID_INSN(1, 0, packed);
}

static inline void cnn_start_mac(void)
{
    CNN_ALU_VOID_INSN(2, 0, 0);
}

static inline void cnn_start_pool(void)
{
    CNN_ALU_VOID_INSN(4, 0, 0);
}

static inline void cnn_clear_acc(void)
{
    CNN_ALU_VOID_INSN(5, 0, 0);
}

static inline void cnn_acc_mac(void)
{
    CNN_ALU_VOID_INSN(6, 0, 0);
}

static inline void cnn_apply_relu(void)
{
    CNN_ALU_VOID_INSN(7, 0, 0);
}

static inline void cnn_add_bias(int32_t bias)
{
    CNN_ALU_VOID_INSN(0, 1, bias);
}

static inline void cnn_requant_relu(int32_t multiplier)
{
    CNN_ALU_VOID_INSN(1, 1, multiplier);
}

static inline void cnn_mac_pack4(uint32_t act_packed, uint32_t weight_packed)
{
    CNN_ALU_VOID2_INSN(2, 1, act_packed, weight_packed);
}

static inline uint32_t cnn_pool4_read(uint32_t act_packed)
{
    return CNN_ALU_READ_INSN(3, 1, act_packed);
}

static inline uint32_t cnn_bias_requant_relu_read(int32_t bias, int32_t multiplier)
{
    return CNN_ALU_READ2_INSN(4, 1, bias, multiplier);
}

static inline uint32_t cnn_pack4(int8_t b0, int8_t b1, int8_t b2, int8_t b3)
{
    return ((uint32_t)(uint8_t)b0) |
           ((uint32_t)(uint8_t)b1 << 8) |
           ((uint32_t)(uint8_t)b2 << 16) |
           ((uint32_t)(uint8_t)b3 << 24);
}

#endif

#endif
