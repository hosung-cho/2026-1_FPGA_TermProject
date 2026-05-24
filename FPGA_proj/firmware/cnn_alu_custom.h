#ifndef CNN_ALU_CUSTOM_H
#define CNN_ALU_CUSTOM_H

#include <stdint.h>

/*
 * RV32I custom-0 CNN ALU instruction format.
 *
 *   opcode  = 0001011b (custom-0)
 *   rs1     = source register passed to CNN_ALU_Top.rs1_data_V
 *   rd      = destination register for CNN_ALU_Top.rd_data_V
 *   cnn_op  = {funct7[0], funct3}
 *
 * Encoding:
 *   [31:25] funct7, bit 25 is cnn_op[3]
 *   [19:15] rs1
 *   [14:12] funct3, cnn_op[2:0]
 *   [11:7]  rd
 *   [6:0]   0001011
 */

#define CNN_CUSTOM_OPCODE 0x0Bu

#define CMD_LOAD_W_PACK4  0u
#define CMD_LOAD_A_PACK4  1u
#define CMD_START_MAC     2u
#define CMD_GET_RES       3u
#define CMD_START_POOL    4u
#define CMD_CLEAR_ACC     5u
#define CMD_ACC_MAC       6u
#define CMD_APPLY_RELU    7u
#define CMD_ADD_BIAS      8u
#define CMD_REQUANT_RELU  9u

#define CNN_ENCODE(op, rd, rs1) \
    (((((op) >> 3) & 0x1u) << 25) | \
     (((rs1) & 0x1Fu) << 15) | \
     (((op) & 0x7u) << 12) | \
     (((rd) & 0x1Fu) << 7) | \
     CNN_CUSTOM_OPCODE)

#endif
