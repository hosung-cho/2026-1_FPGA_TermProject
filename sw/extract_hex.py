#!/usr/bin/env python3
import os
import subprocess
import struct

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    test_dir = os.path.join(os.path.dirname(script_dir), 'testbench', '3_conv1_e2e')
    
    # 1. Extract .text to rom.bin
    print("[Extract] Extracting rom.bin (.text)...")
    subprocess.run([
        '/opt/riscv32i/bin/riscv32-unknown-elf-objcopy',
        '-O', 'binary',
        '-j', '.text',
        os.path.join(test_dir, 'conv1.elf'),
        os.path.join(test_dir, 'rom.bin')
    ], check=True)
    
    # 2. Extract .data, .rodata, .sdata to ram.bin
    print("[Extract] Extracting ram.bin (.data, .rodata, .sdata)...")
    subprocess.run([
        '/opt/riscv32i/bin/riscv32-unknown-elf-objcopy',
        '-O', 'binary',
        '-j', '.data',
        '-j', '.rodata',
        '-j', '.sdata',
        os.path.join(test_dir, 'conv1.elf'),
        os.path.join(test_dir, 'ram.bin')
    ], check=True)
    
    # 3. Convert rom.bin to imem.hex (ROM: 4096 words = 16KB)
    print("[Convert] Converting rom.bin to imem.hex...")
    with open(os.path.join(test_dir, 'rom.bin'), 'rb') as f:
        rom_data = f.read()
    
    # Pad to 4-byte boundary
    if len(rom_data) % 4 != 0:
        rom_data += b'\x00' * (4 - (len(rom_data) % 4))
        
    # We pad the instruction memory to 4096 words
    rom_words = []
    for i in range(0, len(rom_data), 4):
        rom_words.append(struct.unpack('<I', rom_data[i:i+4])[0])
        
    # Write imem.hex
    with open(os.path.join(test_dir, 'imem.hex'), 'w') as f:
        # We can write one hex word per line
        for w in rom_words:
            f.write(f"{w:08X}\n")
        # Pad the rest with 0 (addi x0, x0, 0)
        for _ in range(4096 - len(rom_words)):
            f.write("00000013\n")
            
    # 4. Convert ram.bin to dmem.hex (RAM: 8192 words = 32KB)
    print("[Convert] Converting ram.bin to dmem.hex...")
    with open(os.path.join(test_dir, 'ram.bin'), 'rb') as f:
        ram_data = f.read()
        
    if len(ram_data) % 4 != 0:
        ram_data += b'\x00' * (4 - (len(ram_data) % 4))
        
    ram_words = []
    for i in range(0, len(ram_data), 4):
        ram_words.append(struct.unpack('<I', ram_data[i:i+4])[0])
        
    # Write dmem.hex
    with open(os.path.join(test_dir, 'dmem.hex'), 'w') as f:
        for w in ram_words:
            f.write(f"{w:08X}\n")
        # Pad the rest with 0
        for _ in range(8192 - len(ram_words)):
            f.write("00000000\n")
            
    print(f"Extraction successful!")
    print(f"imem.hex size: {len(rom_words)} / 4096 words")
    print(f"dmem.hex size: {len(ram_words)} / 8192 words")

if __name__ == '__main__':
    main()
