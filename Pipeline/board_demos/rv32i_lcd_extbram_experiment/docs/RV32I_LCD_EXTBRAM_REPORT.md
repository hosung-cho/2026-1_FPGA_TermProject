# RV32I LeNet LCD External BRAM Experiment Report

## 1. Goal

This variant keeps the verified RV32I + LCD demo, but moves RV32I data memory out of the CPU wrapper and into a visible block-design memory path.

The purpose is to make input data replaceable from the Zynq PS side before each run. The current verified baseline remains in:

```text
Pipeline/board_demos/rv32i_lcd_success
```

This experiment is stored separately in:

```text
Pipeline/board_demos/rv32i_lcd_extbram_experiment
```

## 2. Verified Environment

- Board: RPS-ZYNQ BASE Rev 2.2
- FPGA device: `xc7z020clg484-1`
- Tool: Vivado 2019.1
- Hardware connection: JTAG
- Build project path: `C:/rv32i_lcd_extbram_bd_impl`

## 3. Block Design Structure

```text
ZYNQ7 Processing System
  M_AXI_GP0
    -> AXI Interconnect
       -> RV32I_AxiLite_Bram_Top
          AXI base: 0x43C00000
       -> AXI BRAM Controller
          AXI base: 0x43C40000
          -> BramPortA_RunMux
          -> blk_mem_gen dmem_bram_0 Port A
       -> TFTLCD_AxiLite_Top
          AXI base: 0x43C80000

RV32I CPU
  data read  -> dmem_bram_0 Port B
  data write -> BramPortA_RunMux -> dmem_bram_0 Port A
```

The BRAM mux selects ownership of BRAM Port A:

- `cpu_active = 0`: PS/AXI BRAM Controller owns Port A, used to load or inspect dmem.
- `cpu_active = 1`: RV32I CPU write path owns Port A during inference.

CPU reads use Port B, so the CPU still has a read path while writes go through Port A.

## 4. Address Map

| Peripheral | Base Address | Range | Use |
| --- | ---: | ---: | --- |
| RV32I control/status | `0x43C00000` | 64 KB | Start, status, prediction, debug |
| External dmem BRAM | `0x43C40000` | 128 KB | Runtime-loadable RV32I data memory |
| TFT-LCD framebuffer | `0x43C80000` | 512 KB | 480 x 272 RGB565 framebuffer |

Additional RV32I register:

| Offset | Register | Meaning |
| ---: | --- | --- |
| `0x2C` | cycle_count | Inference cycles from run start until done |

The external dmem BRAM is configured as:

```text
blk_mem_gen
use_bram_block = Stand_Alone
Memory_Type    = True_Dual_Port_RAM
Write_Depth_A  = 32768
Data width     = 32
Address width  = 15 word-address bits
```

## 5. Verified Result

Latest build:

```text
RV32I_PS_LCD_EXTBRAM_BD_WNS=0.085
RV32I_PS_LCD_EXTBRAM_BD_TIMING_OK=1
RV32I_PS_LCD_EXTBRAM_BD_IMPL_OK=1
```

Latest board run:

```text
EXTBRAM_DMEM_WORDS_WRITTEN=32768
EXTBRAM_DMEM_BASEADDR=0x43C40000
EXTBRAM_STATUS_RAW=43C00004:   00000003
EXTBRAM_PRED=7
EXTBRAM_EXPECTED=7
EXTBRAM_PASS=1
```

The current RTL also exposes `EXTBRAM_CYCLE_COUNT`, which can be converted to time as:

```text
latency_seconds = cycle_count / 100,000,000
latency_us      = cycle_count / 100
```

## 6. Important Implementation Note

Vivado initially forced `blk_mem_gen` to 2048 words when it was left in `BRAM_Controller` mode. That was too small for the LeNet dmem image, so the CPU stalled or produced invalid results.

The fix was to set:

```tcl
CONFIG.use_bram_block {Stand_Alone}
CONFIG.Interface_Type {Native}
CONFIG.Write_Depth_A {32768}
CONFIG.Enable_32bit_Address {false}
```

The AXI BRAM Controller still exposes a 128 KB PS-accessible window, but the BRAM itself is now an independent native true dual-port memory.
