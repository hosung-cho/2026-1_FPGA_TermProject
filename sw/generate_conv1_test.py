#!/usr/bin/env python3
import os
import struct
import numpy as np

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    output_dir = os.path.join(script_dir, 'output')
    
    # 1. Load weights
    hex_path = os.path.join(output_dir, 'weights.hex')
    words = []
    with open(hex_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('//'):
                words.append(int(line, 16))
    
    all_bytes = bytearray()
    for w in words:
        all_bytes.extend(struct.pack('<I', w))
        
    # Conv1 offset and size
    w_off = 0
    w_cnt = 150
    b_off = 152
    b_cnt = 6
    
    w_bytes = all_bytes[w_off:w_off + w_cnt]
    conv1_w = np.frombuffer(bytes(w_bytes), dtype=np.int8).reshape(6, 1, 5, 5)
    
    b_bytes = all_bytes[b_off:b_off + b_cnt * 4]
    conv1_b = np.frombuffer(bytes(b_bytes), dtype=np.int32)
    
    # 2. Pad weights to 28 bytes per filter (6 filters, 1 channel)
    conv1_w_padded = np.zeros((6, 28), dtype=np.int8)
    for oc in range(6):
        w_flat = conv1_w[oc, 0].flatten() # 25 bytes
        conv1_w_padded[oc, :25] = w_flat
        # remaining 3 bytes are 0
        
    # 3. Load test image 0
    img_words = []
    with open(os.path.join(output_dir, 'test_images.hex'), 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('//'):
                img_words.append(int(line, 16))
    img_bytes = bytearray()
    for w in img_words:
        img_bytes.extend(struct.pack('<I', w))
    img0 = np.frombuffer(bytes(img_bytes[:784]), dtype=np.uint8)

    # Create target directory
    test_dir = os.path.join(project_dir, 'testbench', '3_conv1_e2e')
    os.makedirs(test_dir, exist_ok=True)
    os.makedirs(os.path.join(test_dir, 'sim'), exist_ok=True)

    # 4. Generate conv1.c
    c_code = []
    c_code.append('#include <stdint.h>')
    c_code.append('')
    c_code.append('// Status variable linked at the very beginning of RAM (starts at 0x00008000)')
    c_code.append('volatile uint32_t status __attribute__((section(".status_section"))) = 0xAA55AA55;')
    c_code.append('')
    c_code.append('// CFU macros')
    c_code.append('#define cfu_clracc() \\')
    c_code.append('    ({ \\')
    c_code.append('        uint32_t rd; \\')
    c_code.append('        asm volatile(".insn r 0x0b, 0, 3, %0, x0, x0" : "=r"(rd)); \\')
    c_code.append('        rd; \\')
    c_code.append('    })')
    c_code.append('')
    c_code.append('#define cfu_mac4(rs1, rs2) \\')
    c_code.append('    ({ \\')
    c_code.append('        uint32_t rd; \\')
    c_code.append('        asm volatile(".insn r 0x0b, 0, 0, %0, %1, %2" : "=r"(rd) : "r"(rs1), "r"(rs2)); \\')
    c_code.append('        rd; \\')
    c_code.append('    })')
    c_code.append('')
    c_code.append('#define cfu_rescale(rs1, rs2) \\')
    c_code.append('    ({ \\')
    c_code.append('        uint32_t rd; \\')
    c_code.append('        asm volatile(".insn r 0x0b, 0, 4, %0, %1, %2" : "=r"(rd) : "r"(rs1), "r"(rs2)); \\')
    c_code.append('        rd; \\')
    c_code.append('    })')
    c_code.append('')
    c_code.append('// Input image')
    c_code.append('const uint8_t img0[784] = {')
    c_code.append('    ' + ', '.join(str(v) for v in img0))
    c_code.append('};')
    c_code.append('')
    c_code.append('// Conv1 Weights (padded to 28 bytes per filter)')
    c_code.append('const int8_t conv1_w_padded[6][28] = {')
    for oc in range(6):
        c_code.append('    {' + ', '.join(str(v) for v in conv1_w_padded[oc]) + '},')
    c_code.append('};')
    c_code.append('')
    c_code.append('// Conv1 Bias')
    c_code.append('const int32_t conv1_b[6] = {')
    c_code.append('    ' + ', '.join(str(v) for v in conv1_b))
    c_code.append('};')
    c_code.append('')
    c_code.append('// Conv1 shift value')
    c_code.append('#define CONV1_SHIFT 9')
    c_code.append('')
    c_code.append('// Output buffer')
    c_code.append('uint8_t conv1_out[24][24][6];')
    c_code.append('')
    c_code.append('void main() {')
    c_code.append('    uint8_t window[28];')
    c_code.append('    window[25] = 0;')
    c_code.append('    window[26] = 0;')
    c_code.append('    window[27] = 0;')
    c_code.append('')
    c_code.append('    for (int oc = 0; oc < 6; oc++) {')
    c_code.append('        uint32_t w0 = *(uint32_t*)&conv1_w_padded[oc][0];')
    c_code.append('        uint32_t w1 = *(uint32_t*)&conv1_w_padded[oc][4];')
    c_code.append('        uint32_t w2 = *(uint32_t*)&conv1_w_padded[oc][8];')
    c_code.append('        uint32_t w3 = *(uint32_t*)&conv1_w_padded[oc][12];')
    c_code.append('        uint32_t w4 = *(uint32_t*)&conv1_w_padded[oc][16];')
    c_code.append('        uint32_t w5 = *(uint32_t*)&conv1_w_padded[oc][20];')
    c_code.append('        uint32_t w6 = *(uint32_t*)&conv1_w_padded[oc][24];')
    c_code.append('')
    c_code.append('        int32_t bias = conv1_b[oc];')
    c_code.append('')
    c_code.append('        for (int oh = 0; oh < 24; oh++) {')
    c_code.append('            for (int ow = 0; ow < 24; ow++) {')
    c_code.append('                // Extract 25 pixels')
    c_code.append('                for (int ky = 0; ky < 5; ky++) {')
    c_code.append('                    int r = oh + ky;')
    c_code.append('                    int c = ow;')
    c_code.append('                    window[ky * 5 + 0] = img0[r * 28 + c + 0];')
    c_code.append('                    window[ky * 5 + 1] = img0[r * 28 + c + 1];')
    c_code.append('                    window[ky * 5 + 2] = img0[r * 28 + c + 2];')
    c_code.append('                    window[ky * 5 + 3] = img0[r * 28 + c + 3];')
    c_code.append('                    window[ky * 5 + 4] = img0[r * 28 + c + 4];')
    c_code.append('                }')
    c_code.append('')
    c_code.append('                // Pack window into words')
    c_code.append('                uint32_t x0 = *(uint32_t*)&window[0];')
    c_code.append('                uint32_t x1 = *(uint32_t*)&window[4];')
    c_code.append('                uint32_t x2 = *(uint32_t*)&window[8];')
    c_code.append('                uint32_t x3 = *(uint32_t*)&window[12];')
    c_code.append('                uint32_t x4 = *(uint32_t*)&window[16];')
    c_code.append('                uint32_t x5 = *(uint32_t*)&window[20];')
    c_code.append('                uint32_t x6 = *(uint32_t*)&window[24];')
    c_code.append('')
    c_code.append('                // Perform 7 MAC4 operations using CPU accumulation')
    c_code.append('                int32_t acc = bias;')
    c_code.append('                acc += (int32_t)cfu_mac4(x0, w0);')
    c_code.append('                acc += (int32_t)cfu_mac4(x1, w1);')
    c_code.append('                acc += (int32_t)cfu_mac4(x2, w2);')
    c_code.append('                acc += (int32_t)cfu_mac4(x3, w3);')
    c_code.append('                acc += (int32_t)cfu_mac4(x4, w4);')
    c_code.append('                acc += (int32_t)cfu_mac4(x5, w5);')
    c_code.append('                acc += (int32_t)cfu_mac4(x6, w6);')
    c_code.append('')
    c_code.append('                // Rescale + implicit ReLU')
    c_code.append('                uint32_t res = cfu_rescale(acc, CONV1_SHIFT);')
    c_code.append('                conv1_out[oh][ow][oc] = (uint8_t)res;')
    c_code.append('            }')
    c_code.append('        }')
    c_code.append('    }')
    c_code.append('')
    c_code.append('    // Verify first few non-zero outputs')
    c_code.append('    int success = 1;')
    c_code.append('    if (conv1_out[3][2][5] != 9) success = 0;')
    c_code.append('    if (conv1_out[3][3][5] != 30) success = 0;')
    c_code.append('    if (conv1_out[3][4][5] != 56) success = 0;')
    c_code.append('    if (conv1_out[3][5][5] != 72) success = 0;')
    c_code.append('    if (conv1_out[3][6][5] != 70) success = 0;')
    c_code.append('')
    c_code.append('    if (conv1_out[5][2][3] != 35) success = 0;')
    c_code.append('    if (conv1_out[5][3][3] != 60) success = 0;')
    c_code.append('    if (conv1_out[5][4][3] != 50) success = 0;')
    c_code.append('')
    c_code.append('    if (success) {')
    c_code.append('        status = 0x12345678; // SUCCESS')
    c_code.append('    } else {')
    c_code.append('        status = 0xDEADBEEF; // FAILURE')
    c_code.append('    }')
    c_code.append('}')
    c_code.append('')

    with open(os.path.join(test_dir, 'conv1.c'), 'w') as f:
        f.write('\n'.join(c_code))
    print(f"Generated: {os.path.join(test_dir, 'conv1.c')}")

    # 5. Generate startup.S
    s_code = """
.section .text.init
.global _start
_start:
    # Set stack pointer (end of 32KB RAM starting at 0x8000 -> 0x00010000)
    li sp, 0x00010000
    # Call main
    jal ra, main
    # Loop forever (halting condition)
    jal x0, .
"""
    with open(os.path.join(test_dir, 'startup.S'), 'w') as f:
        f.write(s_code.strip() + '\n')
    print(f"Generated: {os.path.join(test_dir, 'startup.S')}")

    # 6. Generate link.ld
    ld_code = """
MEMORY
{
  rom (rx)  : ORIGIN = 0x00000000, LENGTH = 16K
  ram (rwx) : ORIGIN = 0x00008000, LENGTH = 32K
}

SECTIONS
{
  .text : {
    *(.text.init)
    *(.text)
    *(.text.*)
  } > rom

  .data : {
    *(.status_section)
    *(.data)
    *(.data.*)
    *(.rodata)
    *(.rodata.*)
    *(.sdata)
    *(.sdata.*)
  } > ram

  .bss : {
    *(.bss)
    *(.bss.*)
    *(.sbss)
    *(.sbss.*)
  } > ram
}
"""
    with open(os.path.join(test_dir, 'link.ld'), 'w') as f:
        f.write(ld_code.strip() + '\n')
    print(f"Generated: {os.path.join(test_dir, 'link.ld')}")

if __name__ == '__main__':
    main()
