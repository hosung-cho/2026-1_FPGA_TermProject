RISCV_PREFIX ?= riscv-none-elf-
CC := $(RISCV_PREFIX)gcc
OBJCOPY := $(RISCV_PREFIX)objcopy
OBJDUMP := $(RISCV_PREFIX)objdump

CFLAGS := -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -ffreestanding -fno-builtin -O2 -Wall -Wextra
LDFLAGS := -T linker.ld -Wl,--gc-sections
LDLIBS := -lgcc

SMOKE_OBJS := startup.o cnn_smoke.o cnn_alu_custom_ops.o
LENET_OBJS := startup.o lenet_infer.o

.PHONY: all clean disasm

all: cnn_smoke_imem.hex lenet_infer_imem.hex

cnn_smoke.elf: $(SMOKE_OBJS) linker.ld
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(SMOKE_OBJS) $(LDLIBS)

lenet_infer.elf: $(LENET_OBJS) linker.ld
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(LENET_OBJS) $(LDLIBS)

cnn_smoke.bin: cnn_smoke.elf
	$(OBJCOPY) -O binary $< $@

lenet_infer.bin: lenet_infer.elf
	$(OBJCOPY) -O binary $< $@

cnn_smoke_imem.hex: cnn_smoke.bin
	powershell -NoProfile -ExecutionPolicy Bypass -File bin_to_imem_hex.ps1 $< $@

lenet_infer_imem.hex: lenet_infer.bin
	powershell -NoProfile -ExecutionPolicy Bypass -File bin_to_imem_hex.ps1 $< $@

disasm: cnn_smoke.elf lenet_infer.elf
	$(OBJDUMP) -d cnn_smoke.elf > cnn_smoke.dis
	$(OBJDUMP) -d lenet_infer.elf > lenet_infer.dis

clean:
	del /Q *.o *.elf *.bin *.hex *.dis 2>NUL || exit 0
