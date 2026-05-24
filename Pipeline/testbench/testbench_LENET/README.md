# LeNet RV32I E2E Testbench

This testbench runs the RV32I firmware version of the LeNet INT8 inference flow.

Expected generated inputs:

```text
FPGA_proj/firmware/lenet_infer_imem.hex
FPGA_proj/firmware/lenet_digit7_dmem.mem
```

Generate `lenet_digit7_dmem.mem`:

```powershell
cd ..\..\..\FPGA_proj\firmware
powershell -NoProfile -ExecutionPolicy Bypass -File make_lenet_dmem.ps1
```

Generate `lenet_infer_imem.hex` after installing a RISC-V GCC toolchain:

```powershell
cd ..\..\..\FPGA_proj\firmware
make lenet_infer_imem.hex
```

Run simulation:

```powershell
cd ..\..\Pipeline\testbench\testbench_LENET
iverilog -g2012 -o sim_lenet.vvp ..\..\src\rtl\basic_modules.v ..\..\src\rtl\rv32i_cpu.v ..\..\src\rtl\inst_memory.v ..\..\src\rtl\data_memory.v ..\..\src\rtl\cnn_alu\CNN_ALU_Top_mac_mdEe.v ..\..\src\rtl\cnn_alu\CNN_ALU_Top_mux_3bkb.v ..\..\src\rtl\cnn_alu\CNN_ALU_Top_mux_8cud.v ..\..\src\rtl\cnn_alu\CNN_ALU_Top.v ..\..\src\rtl\RV32I_System.v RV32I_System_tb.v
vvp sim_lenet.vvp
```
