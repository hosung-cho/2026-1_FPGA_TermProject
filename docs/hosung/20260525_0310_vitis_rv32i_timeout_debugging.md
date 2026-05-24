# 2026-05-25 Vitis RV32I Host Timeout Debugging Summary

## Problem
- Symptom: Vitis host loads IMEM/DMEM, releases reset, then polls a status word in DMEM and times out.
- Simulation (testbench) passes, but board run times out.
- User requested: avoid RTL edits; fix on C/host/linker side.

## System Map (PS <-> BRAM)
- IMEM PS base: `0xA0000000` (axi_bram_ctrl_0)
- DMEM PS base: `0xA2000000` (axi_bram_ctrl_1)
- GPIO base: `0xA3000000`
- IMEM size: 32 KB (4096 words)
- DMEM size: 64 KB (16384 words)

## Status Signaling
- Success: `0x12345678`
- Failure: `0xDEADBEEF`
- Host polls `DMEM_BRAM_BASE + STATUS_OFFSET`.

## Hypotheses Considered
1. Host polling the wrong status offset (0x0 vs 0x8000).
2. BRAM byte/word addressing mismatch (byte lanes or address scaling).
3. Program never reaches status write (stuck in long software pipeline or wrong image loaded).

## Key Investigations and Tests
### 1) Host diagnostics
- Added early status read after reset and periodic polling logs.
- Added optional dual-offset probing for `0x0` and `0x8000`.

### 2) BRAM byte-lane probe (addr_width_probe)
- Wrote/loaded a small RV32I program to test SB/LW/SW behavior.
- Result: byte-lanes behave correctly; word values updated as expected.

### 3) Linker and image pipeline
- `testbench/5-2_original/link.ld` places `.status_section` at RAM origin.
- `extract_hex.py` and `hex_to_c.py` generate `imem_image.c` and `dmem_image.c`.
- When RAM origin moved to 0x0, `ld` reports overlap; fixed by adding `-Wl,--no-check-sections` in `compile.sh`.

### 4) ILA signals
- ILA already wired to RV32I internal nets (instruction, fetch/data addr, write data, byte enables, write enable, halt).
- Can be used to confirm whether CPU continues executing and whether writes to DMEM occur.

## Code Changes (C/Host/Linker)
### Host (Vitis)
- File: `FPGA/260524_original_phase_ultra96/Vitis/vitis_lenet5.c`
- Key updates:
  - `STATUS_OFFSET` set to `0x00000000` for base-0 layout.
  - `ENABLE_ALT_STATUS_CHECK` added to optionally probe legacy `0x8000` layout.
  - Polling logs simplified when alt check disabled.

### Testbench (RV32I software)
- File: `testbench/5-2_original/lenet5_sw.c`
- Added progress markers to `s_block.status`:
  - `0x11111111`: main entry
  - `0x22220001` .. `0x22220009`: per-stage progress

### Linker and build pipeline
- File: `testbench/5-2_original/link.ld`
  - RAM origin set to `0x00000000` for DMEM base-0 layout (when desired).
- File: `testbench/5-2_original/compile.sh`
  - Added `-Wl,--no-check-sections` to allow `.text` and `.data` to share LMA=0 in a Harvard layout.

## Observed Runtime Logs (Latest)
- Host loads IMEM/DMEM correctly.
- DMEM before reset: `0xAA55AA55` at base.
- After reset: status becomes `0x11111111` (main entry marker).
- Polling stays at `0x11111111` and times out.

Interpretation:
- CPU reaches `main()` but does not advance to later stages OR new images were not loaded into the Vitis project.
- If progress markers are not seen, the Vitis images may be stale.

## Current Status
- RTL restored by user.
- Host now polls base-0 status only.
- Software marker shows `main()` reached, but no further progress.

## Next Steps
1) Rebuild RV32I software and regenerate images:
   - `./compile.sh`
   - `python3 extract_hex.py`
   - `python3 hex_to_c.py imem.hex --name imem_image --output imem_image.c`
   - `python3 hex_to_c.py dmem.hex --name dmem_image --output dmem_image.c`
2) Copy updated `imem_image.c` and `dmem_image.c` into the Vitis project and rebuild the Vitis app.
3) Re-run and check status progression:
   - Expect `0x22220001` and later stage codes if updated images are loaded.
4) If still stuck at `0x11111111`:
   - Add finer-grain status updates around `prepare_weights()` or first loop.
   - Use ILA to confirm fetch/execute and DMEM writes.
   - Temporarily reduce workload (skip heavy loops) to confirm forward progress.

## Notes
- The base-0 DMEM layout is valid for a Harvard IMEM/DMEM split, but requires linker overlap checks to be disabled.
- If legacy `0x8000` layout is required, set `ENABLE_ALT_STATUS_CHECK` to `1` and update software/linker accordingly.
