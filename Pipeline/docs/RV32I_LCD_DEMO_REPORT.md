# RV32I LeNet LCD Board Demo Report

## 1. Project Goal

This project ports the RV32I-based LeNet INT8 inference design to a Zynq-7020 board and displays the inference result on the on-board 4.3 inch TFT-LCD.

The current verified demo runs one preloaded digit image, performs inference in the RV32I system, reads the prediction through AXI-Lite, and writes a visual result to the LCD framebuffer.

## 2. Verified Board Environment

- Board: RPS-ZYNQ BASE Rev 2.2
- FPGA device: `xc7z020clg484-1`
- Tool: Vivado 2019.1
- Hardware connection:
  - JTAG connected
  - USB UART detected as COM3, but the current demo uses XSDB/JTAG memory access
- Final LCD project path:
  - `C:/rv32i_lcd_bd_impl/rv32i_lenet_ps_lcd_bd_impl.xpr`

## 3. Final Block Design Structure

```text
ZYNQ7 Processing System
  M_AXI_GP0
    -> AXI Interconnect
       -> RV32I_AxiLite_Top
          AXI base: 0x43C00000
       -> TFTLCD_AxiLite_Top
          AXI base: 0x43C80000

PS FCLK0 = 100 MHz
  -> AXI interconnect
  -> RV32I_AxiLite_Top
  -> TFTLCD AXI write side

PS FCLK1 = 25 MHz
  -> TFTLCD timing input
  -> internal divide-by-2 opclk = 12.5 MHz
```

The LCD framebuffer is implemented as inferred block RAM inside `TFTLCD_AxiLite_Top.v`, not as a visible `Block Memory Generator` IP in the block design.

```verilog
(* ram_style = "block" *) reg [15:0] mem [0:131071];
```

## 4. Important Source Files

| File | Purpose |
| --- | --- |
| `Pipeline/src/rtl/RV32I_AxiLite_Top.v` | AXI-Lite wrapper for RV32I control/status/result registers |
| `Pipeline/src/rtl/TFTLCD_AxiLite_Top.v` | AXI-Lite LCD framebuffer and TFT-LCD timing generator |
| `Pipeline/vivado_board/run_ps_lcd_bd_impl.tcl` | Builds the full Zynq PS + RV32I + LCD block design |
| `Pipeline/vivado_board/program_ps_lcd_bd_bit.tcl` | Programs the generated LCD bitstream through Vivado hardware manager |
| `Pipeline/vivado_board/xsdb_lcd_colorbars.tcl` | Writes red/green/blue/white color bars to LCD framebuffer |
| `Pipeline/vivado_board/xsdb_lcd_digit_demo.tcl` | Runs RV32I inference and draws the predicted digit on LCD |
| `Pipeline/vivado_board/tft_lcd.xdc` | TFT-LCD external pin constraints |
| `Pipeline/vivado_board/imem.hex` | RV32I instruction memory image |
| `Pipeline/vivado_board/lenet_digit7_dmem.mem` | Data memory image for the current digit-7 demo |

## 5. Address Map

| Peripheral | Base Address | Range | Use |
| --- | ---: | ---: | --- |
| RV32I AXI-Lite wrapper | `0x43C00000` | 64 KB | Control, status, prediction result |
| TFT-LCD framebuffer | `0x43C80000` | 512 KB | 480 x 272 RGB565 framebuffer |

RV32I register map:

| Offset | Register | Meaning |
| ---: | --- | --- |
| `0x00` | control | bit1 reset pulse, bit0 run enable |
| `0x04` | status | bit0 done, bit1 pass |
| `0x08` | pred | predicted digit |
| `0x0C` | expected | expected digit |
| `0x10` | heartbeat | running/debug counter |
| `0x14` | pc | RV32I program counter |

## 6. Verified Results

### No-LCD PS/PL Version

- RV32I AXI base: `0x43C00000`
- Timing result: `RV32I_PS_BD_WNS=0.066`
- Hardware result:
  - `PRED=7`
  - `EXPECTED=7`
  - `RV32I_XSDB_PASS=1`

### LCD Version

Latest verified LCD build:

- RV32I AXI base: `0x43C00000`
- LCD AXI base: `0x43C80000`
- Timing result after line-address fix: `RV32I_PS_LCD_BD_WNS=0.074`
- Hardware result:
  - Color bars display correctly as stable vertical bars
  - Digit demo displays a large green `7`
  - `LCD_DIGIT_DEMO_PRED=7`
  - `LCD_DIGIT_DEMO_EXPECTED=7`
  - `LCD_DIGIT_DEMO_PASS=1`

## 7. LCD Debug History

Initial LCD output showed moving noisy lines. The first issue was a mismatch with the board-provided LCD timing example:

- Original failed timing used counters that effectively ran one count too long.
- Fixed timing:
  - Horizontal counter: `0..524`
  - Vertical counter: `0..285`

After that, the display became stable but the color bars appeared diagonally shifted. This was caused by framebuffer read address drift between LCD lines. The fix was to resynchronize the framebuffer read address to the start of each 480-pixel line.

Final observed output:

- Color bars are vertical and stable.
- Digit result screen is stable.

## 8. Current Limitations

The current design is a working single-image demo. The digit-7 input data is preloaded through `lenet_digit7_dmem.mem` during bitstream generation.

This means:

- The RV32I result can be run and displayed.
- The LCD framebuffer can be freely written by PS/XSDB.
- The input image is not yet easily replaceable at runtime.

To support continuous image testing, the next design should expose RV32I data memory through PS-accessible memory.

Two possible directions:

1. Add an AXI-writeable input-image window while keeping the current internal data memory.
2. Move the full RV32I data memory to external `AXI BRAM Controller + Block Memory Generator`.

For a cleaner memory-editable block design, direction 2 is the next experimental variant.

