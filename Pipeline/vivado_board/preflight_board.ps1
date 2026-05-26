$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Resolve-Path (Join-Path $scriptDir "..\..")

$requiredFiles = @(
  "Pipeline\src\rtl\basic_modules.v",
  "Pipeline\src\rtl\rv32i_cpu.v",
  "Pipeline\src\rtl\inst_memory.v",
  "Pipeline\src\rtl\data_memory.v",
  "Pipeline\src\rtl\cnn_alu\mac_pack4_delta.v",
  "Pipeline\src\rtl\cnn_alu\CNN_ALU_Top_mac_mdEe.v",
  "Pipeline\src\rtl\cnn_alu\CNN_ALU_Top_mux_3bkb.v",
  "Pipeline\src\rtl\cnn_alu\CNN_ALU_Top_mux_8cud.v",
  "Pipeline\src\rtl\cnn_alu\CNN_ALU_Top.v",
  "Pipeline\src\rtl\RV32I_System.v",
  "Pipeline\src\rtl\RV32I_Board_Top.v",
  "Pipeline\src\rtl\RV32I_AxiLite_Top.v",
  "FPGA_proj\firmware\lenet_infer_imem.hex",
  "FPGA_proj\firmware\lenet_digit7_dmem.mem",
  "Pipeline\vivado_board\run_board_impl.tcl",
  "Pipeline\vivado_board\run_board_synth_check.tcl",
  "Pipeline\vivado_board\run_axi_synth_check.tcl",
  "Pipeline\vivado_board\run_ps_bd_check.tcl",
  "Pipeline\vivado_board\board_template.xdc"
)

$missing = @()
foreach ($relativePath in $requiredFiles) {
  $path = Join-Path $rootDir $relativePath
  if (-not (Test-Path $path)) {
    $missing += $relativePath
  }
}

if ($missing.Count -gt 0) {
  Write-Host "RV32I board preflight failed: missing required files"
  $missing | ForEach-Object { Write-Host "  - $_" }
  exit 1
}

$boardXdc = Join-Path $scriptDir "board.xdc"
if (-not (Test-Path $boardXdc)) {
  Write-Host "RV32I board preflight warning: board.xdc is not present."
  Write-Host "Copy board_template.xdc to board.xdc and fill in real board pins before bitstream generation."
} else {
  $xdcText = Get-Content $boardXdc -Raw
  $placeholders = @("<CLK_PIN>", "<RESET_PIN>", "<LED0_PIN>", "<LED1_PIN>", "<LED2_PIN>", "<LED3_PIN>", "<LED4_PIN>", "<LED5_PIN>", "<LED6_PIN>", "<LED7_PIN>")
  $remaining = $placeholders | Where-Object { $xdcText.Contains($_) }
  if ($remaining.Count -gt 0) {
    Write-Host "RV32I board preflight failed: board.xdc still has placeholders"
    $remaining | ForEach-Object { Write-Host "  - $_" }
    exit 1
  }
}

Write-Host "RV32I board preflight OK: RTL, firmware images, and Vivado scripts are present."
Write-Host "Next safe check without board pins:"
Write-Host "  vivado -mode batch -source run_board_synth_check.tcl"
