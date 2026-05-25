# RV32I LCD Success Demo Package

This folder preserves the verified RV32I + LeNet + TFT-LCD board demo before starting the external-BRAM memory architecture experiment.

Verified result:

- Board: RPS-ZYNQ BASE Rev 2.2, `xc7z020clg484-1`
- Vivado: 2019.1
- RV32I clock: 100 MHz from PS FCLK0
- LCD timing input: 25 MHz from PS FCLK1
- LCD pixel clock: 12.5 MHz generated inside `TFTLCD_AxiLite_Top`
- RV32I AXI base: `0x43C00000`
- LCD framebuffer AXI base: `0x43C80000`
- Final timing: `RV32I_PS_LCD_BD_WNS=0.074`
- Board result: `PRED=7`, `EXPECTED=7`, `PASS=1`
- LCD result: stable vertical color bars and large green digit `7`

## Folder Contents

```text
rtl/
  RV32I_AxiLite_Top.v
  TFTLCD_AxiLite_Top.v

vivado/
  run_ps_lcd_bd_impl.tcl
  program_ps_lcd_bd_bit.tcl
  xsdb_lcd_colorbars.tcl
  xsdb_lcd_digit_demo.tcl
  tft_lcd.xdc

memory/
  imem.hex
  lenet_digit7_dmem.mem

docs/
  RV32I_LCD_DEMO_REPORT.md
  RV32I_LCD_DEMO_RUNBOOK.md

artifacts/
  rv32i_lenet_ps_lcd_bd.bit
  rv32i_lenet_ps_lcd_bd.hdf
  checkpoint_20260525_lcd_success.zip
```

## How to Run

Use the canonical runnable files in:

```text
Pipeline/vivado_board
```

The copied files in this package are a branch-friendly snapshot of the successful version. The runbook has the exact commands:

```text
docs/RV32I_LCD_DEMO_RUNBOOK.md
```

Quick run sequence from `Pipeline/vivado_board`:

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source .\program_ps_lcd_bd_bit.tcl
& 'C:\Xilinx\Vivado\2019.1\bin\xsdb.bat' .\xsdb_lcd_colorbars.tcl
& 'C:\Xilinx\Vivado\2019.1\bin\xsdb.bat' .\xsdb_lcd_digit_demo.tcl
```

## Next Variant

The next experiment should not overwrite this baseline. Use a separate external-BRAM variant, for example:

```text
Pipeline/board_demos/rv32i_lcd_extbram_experiment
Pipeline/src/rtl/RV32I_AxiLite_Bram_Top.v
Pipeline/vivado_board/run_ps_lcd_extbram_bd_impl.tcl
```

Target structure:

```text
PS M_AXI_GP0
  -> AXI Interconnect
     -> RV32I control/status AXI-Lite
     -> AXI BRAM Controller
        -> Block Memory Generator
           -> RV32I data memory port
     -> TFTLCD AXI framebuffer
```

