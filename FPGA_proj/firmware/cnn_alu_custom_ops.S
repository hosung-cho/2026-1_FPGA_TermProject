    .section .text
    .align 2

    /*
     * Fixed-register wrappers for the RV32I CNN custom instruction.
     *
     * ABI:
     *   input  a0 = rs1_data
     *   output a0 = rd_data for cnn_get_res, otherwise ignored
     *
     * The custom instruction encoding is:
     *   opcode = 0x0b
     *   cnn_op = {funct7[0], funct3}
     *
     * These wrappers intentionally use fixed rd/rs1 registers so the custom
     * instruction can be emitted as a plain .word without assembler support for
     * custom RISC-V instructions.
     */

    .macro CNN_CUSTOM rd, rs1, op
      .word ((((\op) >> 3) & 1) << 25) | (((\rs1) & 31) << 15) | (((\op) & 7) << 12) | (((\rd) & 31) << 7) | 0x0b
    .endm

    .global cnn_load_w_pack4
cnn_load_w_pack4:
    CNN_CUSTOM 0, 10, 0
    ret

    .global cnn_load_a_pack4
cnn_load_a_pack4:
    CNN_CUSTOM 0, 10, 1
    ret

    .global cnn_start_mac
cnn_start_mac:
    CNN_CUSTOM 0, 0, 2
    ret

    .global cnn_get_res
cnn_get_res:
    CNN_CUSTOM 10, 0, 3
    ret

    .global cnn_start_pool
cnn_start_pool:
    CNN_CUSTOM 0, 0, 4
    ret

    .global cnn_clear_acc
cnn_clear_acc:
    CNN_CUSTOM 0, 0, 5
    ret

    .global cnn_acc_mac
cnn_acc_mac:
    CNN_CUSTOM 0, 0, 6
    ret

    .global cnn_apply_relu
cnn_apply_relu:
    CNN_CUSTOM 0, 0, 7
    ret

    .global cnn_add_bias
cnn_add_bias:
    CNN_CUSTOM 0, 10, 8
    ret

    .global cnn_requant_relu
cnn_requant_relu:
    CNN_CUSTOM 0, 10, 9
    ret
