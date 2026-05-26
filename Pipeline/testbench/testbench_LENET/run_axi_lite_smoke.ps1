$ErrorActionPreference = "Stop"

$rtl = "..\..\src\rtl"
$cnn = "$rtl\cnn_alu"

Copy-Item -Force "..\..\..\FPGA_proj\firmware\lenet_infer_imem.hex" ".\imem.hex"
Copy-Item -Force "..\..\..\FPGA_proj\firmware\lenet_digit7_dmem.mem" ".\lenet_digit7_dmem.mem"

iverilog -g2012 -o sim_axi_lite_smoke.vvp `
  "$rtl\basic_modules.v" `
  "$rtl\rv32i_cpu.v" `
  "$rtl\inst_memory.v" `
  "$rtl\data_memory.v" `
  "$cnn\mac_pack4_delta.v" `
  "$cnn\CNN_ALU_Top_mac_mdEe.v" `
  "$cnn\CNN_ALU_Top_mux_3bkb.v" `
  "$cnn\CNN_ALU_Top_mux_8cud.v" `
  "$cnn\CNN_ALU_Top.v" `
  "$rtl\RV32I_System.v" `
  "$rtl\RV32I_AxiLite_Top.v" `
  ".\RV32I_AxiLite_Top_tb.v"

vvp .\sim_axi_lite_smoke.vvp +FAST_STATUS_STIM +IMEM_HEX=imem.hex +DMEM_HEX=lenet_digit7_dmem.mem
