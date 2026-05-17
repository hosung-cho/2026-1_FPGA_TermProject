#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================="
echo "  RISC-V LeNet-5 Cross-Compilation"
echo "========================================="

# 1. Compile to ELF
echo "[Build] Compiling lenet5.c and startup.S..."
/opt/riscv32i/bin/riscv32-unknown-elf-gcc -march=rv32i -mabi=ilp32 -O2 -nostdlib -fno-builtin -fno-tree-loop-distribute-patterns -T link.ld startup.S lenet5.c -o lenet5.elf

# 2. Extract hex files
echo "[Build] Extracting ROM and RAM hex files..."
python3 extract_hex.py

echo "[Build] Done successfully!"
