# RV32I LCD Demo Runbook

This document lists the commands needed to rebuild, program, and run the current verified RV32I + LCD board demo.

All commands below assume this working directory:

```powershell
cd C:\Users\inseong\.gemini\antigravity\scratch\RV32I-Project\.worktree-inseong\Pipeline\vivado_board
```

## 1. Required Hardware Setup

Connect:

- 5V board power
- JTAG cable
- USB UART cable if needed for later UART tests
- On-board TFT-LCD connected as installed on the RPS-ZYNQ BASE Rev 2.2 board

The current run scripts use JTAG/XSDB. UART COM3 is not required for the current LCD framebuffer demo.

## 2. Rebuild LCD Bitstream

Run:

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source .\run_ps_lcd_bd_impl.tcl
```

Expected success lines:

```text
RV32I_PS_LCD_BD_TIMING_OK=1
RV32I_PS_LCD_BD_IMPL_OK=1
RV32I_AXI_BASEADDR=0x43C00000
TFTLCD_AXI_BASEADDR=0x43C80000
```

Generated artifacts:

```text
Pipeline/vivado_board/build_ps_lcd_bd_impl/rv32i_lenet_ps_lcd_bd.bit
Pipeline/vivado_board/build_ps_lcd_bd_impl/rv32i_lenet_ps_lcd_bd.hdf
```

The temporary Vivado project is generated at:

```text
C:/rv32i_lcd_bd_impl/rv32i_lenet_ps_lcd_bd_impl.xpr
```

The short `C:/rv32i_lcd_bd_impl` path is intentional. It avoids Windows path length problems in Vivado 2019.1.

## 3. Program the Board

Run:

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source .\program_ps_lcd_bd_bit.tcl
```

Expected success line:

```text
RV32I_LCD_PROGRAM_OK=1
```

## 4. Run LCD Color Bar Test

Run:

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\xsdb.bat' .\xsdb_lcd_colorbars.tcl
```

Expected terminal result:

```text
TFTLCD_COLORBARS_WRITTEN=1
RV32I_PRED_RAW=43C00008:   00000007
RV32I_EXPECTED_RAW=43C0000C:   00000007
RV32I_XSDB_PASS=1
```

Expected LCD result:

```text
Stable vertical color bars:
red | green | blue | white
```

## 5. Run Digit Result LCD Demo

Run:

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\xsdb.bat' .\xsdb_lcd_digit_demo.tcl
```

Expected terminal result:

```text
LCD_DIGIT_DEMO_PRED=7
LCD_DIGIT_DEMO_EXPECTED=7
LCD_DIGIT_DEMO_PASS=1
```

Expected LCD result:

```text
Black background
White border
Large green digit 7
Green status bar
```

## 6. Open the Block Design in Vivado GUI

Run:

```powershell
Start-Process -FilePath 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -ArgumentList 'C:\rv32i_lcd_bd_impl\rv32i_lenet_ps_lcd_bd_impl.xpr'
```

Then open:

```text
Open Block Design -> design_1
```

Check:

- `processing_system7_0`
- `axi_interconnect_0`
- `rv32i_axi_0`
- `tftlcd_axi_0`
- external ports: `DDR`, `FIXED_IO`, `opclk`, `Hsync`, `Vsync`, `R`, `G`, `B`, `TFTLCD_DE_out`, `TFTLCD_Tpower`

In Address Editor:

```text
rv32i_axi_0   0x43C00000
tftlcd_axi_0 0x43C80000
```

## 7. Troubleshooting

If LCD shows moving noise:

- Check that the latest bitstream was programmed.
- Re-run `program_ps_lcd_bd_bit.tcl`.
- Re-run `xsdb_lcd_colorbars.tcl`.

If color bars are stable but diagonal:

- This was fixed by the framebuffer line-address resync in `TFTLCD_AxiLite_Top.v`.
- Rebuild with `run_ps_lcd_bd_impl.tcl`.

If LCD is blank:

- Check TFT-LCD power/backlight.
- Check `TFTLCD_Tpower` and `TFTLCD_DE_out` constraints.
- Check that `tft_lcd.xdc` is included in the LCD build.

If RV32I fails but LCD works:

- Check `imem.hex` and `lenet_digit7_dmem.mem`.
- Rebuild the bitstream.
- Run the no-LCD status script if needed:

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\xsdb.bat' .\xsdb_check_rv32i_status.tcl
```

## 8. Next Experimental Variant

The current verified LCD design should be preserved as the baseline.

The next variant should test a more editable memory architecture:

```text
PS M_AXI_GP0
  -> AXI Interconnect
     -> RV32I control/status AXI-Lite
     -> AXI BRAM Controller
        -> Block Memory Generator
           -> RV32I data memory port
```

Goal:

- PS can rewrite input/data memory at runtime.
- Multiple images can be tested sequentially without regenerating bitstreams.

