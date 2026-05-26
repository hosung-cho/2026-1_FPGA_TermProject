# RV32I LCD External BRAM Runbook

All commands below assume:

```powershell
cd C:\Users\inseong\.gemini\antigravity\scratch\RV32I-Project\.worktree-inseong\Pipeline\vivado_board
```

## 1. Rebuild the Bitstream

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source .\run_ps_lcd_extbram_bd_impl.tcl
```

Expected success lines:

```text
RV32I_PS_LCD_EXTBRAM_BD_TIMING_OK=1
RV32I_PS_LCD_EXTBRAM_BD_IMPL_OK=1
RV32I_AXI_BASEADDR=0x43C00000
DMEM_AXI_BASEADDR=0x43C40000
TFTLCD_AXI_BASEADDR=0x43C80000
```

Generated files:

```text
Pipeline/vivado_board/build_ps_lcd_extbram_bd_impl/rv32i_lenet_ps_lcd_extbram_bd.bit
Pipeline/vivado_board/build_ps_lcd_extbram_bd_impl/rv32i_lenet_ps_lcd_extbram_bd.hdf
```

## 2. Program the Board

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat' -mode batch -source .\program_ps_lcd_extbram_bd_bit.tcl
```

If this finishes with exit code 0, continue to the XSDB run.

## 3. Run External BRAM Digit Demo

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\xsdb.bat' .\xsdb_lcd_extbram_digit_demo.tcl
```

Expected result:

```text
EXTBRAM_DMEM_WORDS_WRITTEN=32768
EXTBRAM_DMEM_BASEADDR=0x43C40000
EXTBRAM_CYCLE_COUNT=<cycle count>
EXTBRAM_LATENCY_US_AT_100MHZ=<cycle count / 100>
EXTBRAM_PRED=7
EXTBRAM_EXPECTED=7
EXTBRAM_PASS=1
```

The cycle counter measures RV32I inference latency from run start until the done flag is observed in hardware. The design runs at 100 MHz, so:

```text
latency_us = cycle_count / 100
```

Expected LCD output:

```text
Black background
White border
Large green digit 7
Green status bar
```

## 4. Optional BRAM Readback Probe

Use this before running the CPU if PS-side BRAM access looks suspicious:

```powershell
& 'C:\Xilinx\Vivado\2019.1\bin\xsdb.bat' .\xsdb_extbram_readback_probe.tcl
```

Expected low-address readback:

```text
EXTBRAM_PROBE_0=43C40000:   11223344
EXTBRAM_PROBE_4=43C40004:   55667788
```

## 5. Package Contents

```text
artifacts/  verified bit, hdf, timing/utilization/DRC reports
docs/       this runbook and result report
memory/     imem and digit-7 dmem images
rtl/        external dmem RTL wrappers and LCD AXI wrapper snapshot
vivado/     build, program, XSDB, and XDC scripts
```
