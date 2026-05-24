# RV32I + CNN_ALU Vivado Implementation Check

Target:

- Device: `xc7z020clg484-1`
- Clock: `10.000 ns`
- Top: `RV32I_System`
- Firmware image: `FPGA_proj/firmware/lenet_infer_imem.hex`

Run:

```powershell
cd Pipeline\vivado_impl
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source .\run_impl.tcl
```

Current result:

```text
RV32I_LENET_IMPL_TIMING_OK=1
post-route WNS = +0.231 ns
post-route TNS = 0.000 ns
```

Post-route resource summary:

```text
Slice LUTs       : 3113
LUT as Memory    : 0
Slice Registers  : 3090
BRAM Tiles       : 32
DSPs             : 16
CARRY4           : 180
```

Hierarchy summary:

```text
iDMem            : 32 LUTs, 32 BRAM tiles
iIMem            : 416 LUTs
icpu             : 2661 LUTs, 3090 FFs, 16 DSPs
i_cnn_alu_top    : 1194 LUTs, 1481 FFs, 16 DSPs
```

Key fixes made for timing:

- `data_memory` was changed from asynchronous LUTRAM-style read to synchronous BRAM-style read.
- The CPU now drives separate data-memory read and write addresses.
- Load data is no longer included in the EX/MEM forwarding candidate path.
- The CPU ALU adder was changed from a hand-built 32-bit ripple adder to a carry-chain-friendly `+` implementation.
- Load/store address generation now uses a dedicated `base + immediate` path instead of the full ALU result mux.
- The implementation script uses Explore/AggressiveExplore directives for place/route margin.

Functional check:

```powershell
cd Pipeline\testbench\testbench_LENET
powershell -NoProfile -ExecutionPolicy Bypass -File .\run_lenet_0_to_9.ps1
```

Latest Verilator E2E result: MNIST digit `0` through `9` all predicted correctly.

Performance snapshot from the same 0-9 Verilator run:

```text
cycles per inference      : 8,625,963 - 8,625,966
time at 100 MHz           : about 86.26 ms per image
CNN custom instructions   : 131,410 per image
CNN wait stall cycles     : 991,186 per image
load-use stall cycles     : 240,000 per image
total stall cycles        : 1,231,186 per image
flushes                   : about 419,906 - 419,909 per image
```

No-CNN-ALU software baseline, built from the same `lenet_infer.c` with
`CNN_ALU_DISABLE`:

```text
cycles per inference      : 86,036,124 - 86,101,621
average cycles            : 86,078,010.3
time at 100 MHz           : about 860.78 ms per image
CNN custom instructions   : 0
```

Comparison:

```text
CNN_ALU average cycles    : 8,625,964.3
software average cycles   : 86,078,010.3
speedup                   : about 9.98x
```

Notes:

- A previous run without copying `lenet_infer_imem.hex` produced a false timing pass because the instruction ROM synthesized mostly as NOPs and optimized away the real LeNet path.
- `run_impl.tcl` copies `lenet_infer_imem.hex` into the Vivado implementation directory before synthesis so the real firmware path is preserved.
- Top-level debug outputs are still present for keeping meaningful implementation paths visible; real board bitstream work should replace them with proper XDC constraints or an internal debug strategy.
