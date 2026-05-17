#!/usr/bin/env python3
"""
Conv1 E2E RTL Test Generator
==============================
Conv1 레이어 한 포지션(0,0)의 6개 필터 출력을 RTL에서 검증하기 위한
imem.hex, dmem.hex, expected values를 생성.

PyTorch 없이 독립적으로 동작 (가중치 직접 지정 가능).
"""
import struct, os, sys
import numpy as np

# ============================================================
# RISC-V instruction encoder
# ============================================================
def r_type(funct7, rs2, rs1, funct3, rd, opcode):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def i_type(imm12, rs1, funct3, rd, opcode):
    return ((imm12 & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def s_type(imm12, rs2, rs1, funct3, opcode):
    imm_hi = (imm12 >> 5) & 0x7F
    imm_lo = imm12 & 0x1F
    return (imm_hi << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_lo << 7) | opcode

def LW(rd, offset, rs1):    return i_type(offset, rs1, 0b010, rd, 0b0000011)
def SW(rs2, offset, rs1):   return s_type(offset, rs2, rs1, 0b010, 0b0100011)
def ADDI(rd, rs1, imm):     return i_type(imm, rs1, 0b000, rd, 0b0010011)
def ADD(rd, rs1, rs2):       return r_type(0b0000000, rs2, rs1, 0b000, rd, 0b0110011)
def LUI(rd, imm20):          return ((imm20 & 0xFFFFF) << 12) | (rd << 7) | 0b0110111
def MAC4(rd, rs1, rs2):      return r_type(0b0000000, rs2, rs1, 0b000, rd, 0b0001011)
def RESCALE(rd, rs1, rs2):   return r_type(0b0000100, rs2, rs1, 0b000, rd, 0b0001011)
def RELU(rd, rs1):           return r_type(0b0000001, 0, rs1, 0b000, rd, 0b0001011)
def HALT():                   return 0x0000006F  # JAL x0, 0

# ============================================================
# Conv1 reference computation (hardware-matched)
# ============================================================
def hw_conv1_one_pixel(patch_5x5, weights_5x5, bias, shift):
    """Compute one Conv1 output pixel using exact hardware math"""
    acc = int(bias)
    for i in range(25):
        acc += int(np.int8(patch_5x5[i])) * int(np.int8(weights_5x5[i]))
    
    # RESCALE: clamp(round_shift(acc, shift), 0, 255)
    if acc < 0:
        return 0
    if shift > 0:
        val = (acc + (1 << (shift - 1))) >> shift
    else:
        val = acc
    return min(255, max(0, val))

# ============================================================
# Main generator
# ============================================================
def main():
    out_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)))
    
    # --- Test data: use simple known values ---
    # Image 5x5 patch (uint8 pixel values, treating as signed int8 in MAC)
    # Using recognizable pattern
    np.random.seed(42)
    patch = np.random.randint(0, 200, size=25, dtype=np.uint8)
    
    # Conv1 weights: 6 filters × 5×5 = 150 weights (int8)
    # Use small known values for verification
    np.random.seed(123)
    weights = np.random.randint(-30, 30, size=(6, 25), dtype=np.int8)
    
    # Biases (int32)
    biases = np.array([10, -5, 20, 0, -10, 15], dtype=np.int32)
    
    # Shift value
    shift = 5
    
    # --- Compute reference outputs ---
    expected = []
    for f in range(6):
        val = hw_conv1_one_pixel(patch, weights[f], biases[f], shift)
        expected.append(val)
    
    print("=" * 60)
    print("  Conv1 E2E Test Data Generator")
    print("=" * 60)
    print(f"  Image patch (25 uint8): {list(patch)}")
    print(f"  Shift: {shift}")
    for f in range(6):
        print(f"  Filter {f}: bias={biases[f]:4d}, expected_out={expected[f]:3d}")
    
    # === DATA MEMORY LAYOUT ===
    # 0x000 (words 0-6):   image patch, 25 bytes packed, pad to 28
    # 0x020 (words 8-14):  filter 0 weights, 25 bytes packed, pad to 28  
    # 0x03C (words 15-21): filter 1 weights
    # 0x058 (words 22-28): filter 2 weights
    # 0x074 (words 29-35): filter 3 weights
    # 0x090 (words 36-42): filter 4 weights
    # 0x0AC (words 43-49): filter 5 weights
    # 0x0C8 (words 50-55): biases (6 × int32)
    # 0x0E0 (word 56):     shift value
    # 0x100 (words 64-69): output results (6 words)

    dmem = [0] * 256  # 1024 bytes
    
    # Pack image patch (25 bytes → 7 words)
    patch_padded = np.pad(patch, (0, 3), constant_values=0)  # pad to 28
    for i in range(7):
        dmem[i] = int.from_bytes(patch_padded[i*4:i*4+4].tobytes(), 'little')
    
    # Pack weights for each filter (25 bytes → 7 words each, starting at word 8)
    for f in range(6):
        w_padded = np.pad(weights[f].view(np.uint8), (0, 3), constant_values=0)
        base_word = 8 + f * 7
        for i in range(7):
            dmem[base_word + i] = int.from_bytes(w_padded[i*4:i*4+4].tobytes(), 'little')
    
    # Pack biases (word 50-55)
    for f in range(6):
        dmem[50 + f] = struct.unpack('<I', struct.pack('<i', int(biases[f])))[0]
    
    # Shift value (word 56)
    dmem[56] = shift
    
    # Write dmem.hex
    with open(os.path.join(out_dir, 'dmem.hex'), 'w') as f:
        f.write("// Conv1 E2E Test - Data Memory\n")
        for i, w in enumerate(dmem):
            f.write(f"{w:08X}\n")
    
    # === INSTRUCTION MEMORY ===
    # Register allocation:
    #   x1  = image base (0x000)
    #   x2  = current filter weight base
    #   x3  = bias base (0x0C8)
    #   x4  = shift value
    #   x5  = output base (0x100)
    #   x10 = accumulator
    #   x11,x12 = temp (image chunk, weight chunk)
    #   x13 = MAC4 result
    #   x14 = filter loop counter
    #   x15 = weight stride (28 = 0x1C)
    
    program = []
    
    # Setup base pointers
    program.append(ADDI(1, 0, 0x000))     # x1 = 0x000 (image base)
    program.append(ADDI(2, 0, 0x020))     # x2 = 0x020 (filter 0 weights)
    program.append(ADDI(3, 0, 0x0C8))     # x3 = 0x0C8 (bias base, 50*4=200=0xC8)
    program.append(LW(4, 0x0E0, 0))       # x4 = dmem[0x0E0] = shift
    program.append(ADDI(5, 0, 0x100))     # x5 = 0x100 (output base, 64*4=256=0x100)
    
    # For each filter (unrolled for 6 filters)
    for f in range(6):
        w_base_offset = 0x020 + f * 28     # byte address of filter f weights
        b_offset = 0x0C8 + f * 4           # byte address of bias f
        out_offset = 0x100 + f * 4         # byte address of output f
        
        # Load bias → x10 (accumulator)
        program.append(LW(10, b_offset, 0))  # x10 = bias[f]
        
        # MAC loop: 7 iterations (25 elements, pad last 3 with 0)
        for chunk in range(7):
            img_offset = chunk * 4             # byte offset in image
            wgt_offset = w_base_offset + chunk * 4  # byte offset of weight chunk
            
            program.append(LW(11, img_offset, 0))        # x11 = image[chunk*4 +: 4]
            program.append(LW(12, wgt_offset, 0))         # x12 = weight[chunk*4 +: 4]
            program.append(MAC4(13, 11, 12))               # x13 = MAC4(x11, x12)
            program.append(ADD(10, 10, 13))                # x10 += x13
        
        # Rescale
        program.append(RESCALE(10, 10, 4))     # x10 = RESCALE(x10, x4)
        
        # Store result
        program.append(SW(10, out_offset, 0))  # dmem[out_offset] = x10
    
    # Halt
    program.append(HALT())
    
    # Write imem.hex
    with open(os.path.join(out_dir, 'imem.hex'), 'w') as f:
        f.write("// Conv1 E2E Test - Instruction Memory\n")
        for inst in program:
            f.write(f"{inst & 0xFFFFFFFF:08X}\n")
    
    print(f"\n  Program: {len(program)} instructions")
    print(f"  dmem.hex: {len(dmem)} words")
    
    # Write expected values for testbench
    with open(os.path.join(out_dir, 'expected.txt'), 'w') as f:
        for f_idx in range(6):
            f.write(f"// Filter {f_idx}: expected={expected[f_idx]}\n")
            f.write(f"{expected[f_idx]:08X}\n")
    
    # Generate Verilog testbench check code
    print(f"\n  Expected outputs (for testbench):")
    for f_idx in range(6):
        addr = 64 + f_idx  # word address
        print(f"    dmem[{addr}] = 0x{expected[f_idx]:08X} ({expected[f_idx]})")
    
    print(f"\n  Files written to: {out_dir}")
    print("=" * 60)
    
    return expected

if __name__ == '__main__':
    expected = main()
