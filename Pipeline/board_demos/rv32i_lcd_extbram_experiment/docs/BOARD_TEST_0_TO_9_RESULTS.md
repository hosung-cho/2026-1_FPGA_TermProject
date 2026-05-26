# RV32I LCD External BRAM 0-to-9 Board Test

Date: 2026-05-26

## Test Setup

The cycle-counter bitstream was programmed with:

```powershell
cd C:\Users\inseong\.gemini\antigravity\scratch\RV32I-Project\.worktree-inseong\Pipeline\vivado_board
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source .\program_ps_lcd_extbram_cycle_bd_bit.tcl
```

The 0-to-9 external BRAM test was executed with:

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\xsdb.bat' .\xsdb_lcd_extbram_digits_0_to_9.tcl 1 0 9
```

Each run loads a 32768-word dmem image into the external BRAM, starts the RV32I core, reads the prediction register, reads the hardware cycle counter, and updates the LCD digit display.

## Result Summary

The RTL `EXPECTED_DIGIT` parameter is fixed to 7, so the AXI status pass/fail bit is only meaningful for digit 7. For the 0-to-9 validation, the pass criterion is:

```text
DONE_OK == 1 && PRED == input_digit
```

| Input digit | Predicted | Done OK | Pred OK | Cycle count | Latency at 100 MHz |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 0 | 1 | 1 | 8625966 | 86259.66 us |
| 1 | 1 | 1 | 1 | 8625965 | 86259.65 us |
| 2 | 2 | 1 | 1 | 8625965 | 86259.65 us |
| 3 | 3 | 1 | 1 | 8625963 | 86259.63 us |
| 4 | 4 | 1 | 1 | 8625964 | 86259.64 us |
| 5 | 5 | 1 | 1 | 8625965 | 86259.65 us |
| 6 | 6 | 1 | 1 | 8625965 | 86259.65 us |
| 7 | 7 | 1 | 1 | 8625963 | 86259.63 us |
| 8 | 8 | 1 | 1 | 8625964 | 86259.64 us |
| 9 | 9 | 1 | 1 | 8625963 | 86259.63 us |

```text
EXTBRAM_0_TO_9_TOTAL_RUNS=10
EXTBRAM_0_TO_9_TOTAL_PASS=10
EXTBRAM_0_TO_9_ALL_PASS=1
```

## Power Measurement Note

The current setup does not expose a board power monitor through XSDB. For measured power, use an external USB/DC power meter at the 5 V board input.

Recommended report format:

```text
Idle power      = 5 V * idle_current
Running power   = 5 V * running_current
Dynamic increase = running_power - idle_power
```

This is board-level input power, so it includes Zynq PS/PL, DDR, LCD/backlight, regulators, and peripherals.

## RV32I-only Comparison

A second bitstream was built with the same PS, AXI, external BRAM IP, LCD, clock, and cycle counter, but with the CNN_ALU RTL excluded from the design:

```text
RV32I_ENABLE_CNN=0
RV32I_IMEM_HEX=FPGA_proj/firmware/lenet_infer_no_cnn_imem.hex
```

The no-CNN build result:

```text
RV32I_PS_LCD_EXTBRAM_BD_WNS=0.079
RV32I_PS_LCD_EXTBRAM_BD_TIMING_OK=1
RV32I_PS_LCD_EXTBRAM_BD_IMPL_OK=1
```

The no-CNN 0-to-9 board test also passed:

```text
EXTBRAM_0_TO_9_TOTAL_RUNS=10
EXTBRAM_0_TO_9_TOTAL_PASS=10
EXTBRAM_0_TO_9_ALL_PASS=1
```

| Input digit | CNN_ALU cycles | RV32I-only cycles | RV32I-only latency at 100 MHz |
| ---: | ---: | ---: | ---: |
| 0 | 8625966 | 86082951 | 860829.51 us |
| 1 | 8625965 | 86036124 | 860361.24 us |
| 2 | 8625965 | 86089468 | 860894.68 us |
| 3 | 8625963 | 86101621 | 861016.21 us |
| 4 | 8625964 | 86072350 | 860723.50 us |
| 5 | 8625965 | 86092547 | 860925.47 us |
| 6 | 8625965 | 86084949 | 860849.49 us |
| 7 | 8625963 | 86069220 | 860692.20 us |
| 8 | 8625964 | 86092410 | 860924.10 us |
| 9 | 8625963 | 86058463 | 860584.63 us |

Average:

```text
CNN_ALU average cycles     ~= 8.626 M cycles
RV32I-only average cycles  ~= 86.078 M cycles
Speedup                   ~= 9.98x
```

Post-route resource comparison:

| Resource | CNN_ALU build | RV32I-only build | Difference |
| --- | ---: | ---: | ---: |
| Slice LUTs | 4234 | 3545 | -689 |
| Slice Registers | 3782 | 2516 | -1266 |
| Block RAM Tile | 96 | 96 | 0 |
| DSPs | 20 | 0 | -20 |

The BRAM count is unchanged because both builds keep the same external dmem BRAM and LCD framebuffer structure. The DSP reduction confirms that the HLS CNN_ALU datapath was removed from the RV32I-only bitstream.
