# RV32I CNN Custom Instruction Interface

The RV32I pipeline integrates the HLS `CNN_ALU_Top` as a custom instruction
execution unit in the EX stage.

## Encoding

The instruction uses the RISC-V `custom-0` opcode.

```text
opcode = 0001011b
cnn_op = {funct7[0], funct3}
rs1    = 32-bit input data passed to CNN_ALU_Top.rs1_data_V
rd     = CNN_ALU_Top.rd_data_V writeback destination
```

For commands that only update internal CNN_ALU state, use `rd = x0`.
For `CMD_GET_RES`, use a real destination register.

## Command Codes

| Code | Command |
|---:|---|
| `0` | `CMD_LOAD_W_PACK4` |
| `1` | `CMD_LOAD_A_PACK4` |
| `2` | `CMD_START_MAC` |
| `3` | `CMD_GET_RES` |
| `4` | `CMD_START_POOL` |
| `5` | `CMD_CLEAR_ACC` |
| `6` | `CMD_ACC_MAC` |
| `7` | `CMD_APPLY_RELU` |
| `8` | `CMD_ADD_BIAS` |
| `9` | `CMD_REQUANT_RELU` |

## Pipeline Behavior

When a CNN custom instruction reaches EX stage, the CPU asserts `ap_start` for
one cycle and stalls the pipeline until the HLS block asserts `ap_done`. The
latched CNN result is then passed through the normal EX/MEM and MEM/WB writeback
path.

Integrated RTL files:

- `Pipeline/src/rtl/rv32i_cpu.v`
- `Pipeline/src/rtl/cnn_alu/CNN_ALU_Top.v`
- `Pipeline/src/rtl/cnn_alu/CNN_ALU_Top_mac_mdEe.v`
- `Pipeline/src/rtl/cnn_alu/CNN_ALU_Top_mux_3bkb.v`
- `Pipeline/src/rtl/cnn_alu/CNN_ALU_Top_mux_8cud.v`

Use:

- `cnn_alu_custom.h` for command constants and raw instruction encoding.
- `cnn_alu_custom_ops.S` for fixed-register callable wrappers.
- `cnn_alu_custom_ops.h` from C firmware.

## Smoke Firmware

`cnn_smoke.c` reproduces the RTL smoke test:

```text
weights     = [1, 2, ..., 25]
activations = [2, 2, ..., 2]
expected    = 650
```

It writes the final `cnn_get_res()` value to data memory address `0x00000000`.

Build, when a RISC-V GCC toolchain is available:

```powershell
cd FPGA_proj\firmware
make
```

If the xPack toolchain was downloaded into this repository:

```powershell
$env:PATH = "C:\Users\inseong\.gemini\antigravity\scratch\RV32I-Project\tools\xpack-riscv-none-elf-gcc-15.2.0-1\bin;$env:PATH"
cd C:\Users\inseong\.gemini\antigravity\scratch\RV32I-Project\FPGA_proj\firmware
make lenet_infer_imem.hex
```

If `make` is not installed, run the same compile/link steps manually with
`riscv-none-elf-gcc` and `riscv-none-elf-objcopy`; the generated target is
`lenet_infer_imem.hex`.

The expected output is `cnn_smoke_imem.hex`. The current repository also has a
manually encoded equivalent test at:

```text
Pipeline/testbench/testbench_CNN/imem.hex
```

## LeNet Firmware Draft

`lenet_infer.c` is the RV32I firmware version of
`FPGA_proj/tb_lenet_int8_cnn_alu.cpp`.

Memory layout:

```text
0x00000000.. : LeNet parameters from mem/lenet_params.mem
0x00010000   : 32x32 signed INT8 input image
0x00010F00   : predicted label
0x00010F04   : expected label
0x00010F08   : fc2 logits[0]
...
0x00010F2C   : fc2 logits[9]
0x00010F40   : done flag
0x00011000.. : firmware .data/.bss/stack
```

Generate the data memory image for the digit-7 sample:

```powershell
cd FPGA_proj\firmware
powershell -NoProfile -ExecutionPolicy Bypass -File make_lenet_dmem.ps1
```

This writes `lenet_digit7_dmem.mem`.

Run the LeNet RTL testbench:

```powershell
cd Pipeline\testbench\testbench_LENET
iverilog -g2012 -o sim_lenet.vvp ..\..\src\rtl\basic_modules.v ..\..\src\rtl\rv32i_cpu.v ..\..\src\rtl\inst_memory.v ..\..\src\rtl\data_memory.v ..\..\src\rtl\cnn_alu\CNN_ALU_Top_mac_mdEe.v ..\..\src\rtl\cnn_alu\CNN_ALU_Top_mux_3bkb.v ..\..\src\rtl\cnn_alu\CNN_ALU_Top_mux_8cud.v ..\..\src\rtl\cnn_alu\CNN_ALU_Top.v ..\..\src\rtl\RV32I_System.v RV32I_System_tb.v
vvp sim_lenet.vvp
```

The full LeNet run is cycle-accurate and slow under Icarus Verilog. Use the
`TIMEOUT_CYCLES` parameter override for short progress checks.
