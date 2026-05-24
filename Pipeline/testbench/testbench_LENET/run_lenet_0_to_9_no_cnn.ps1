param(
    [string]$WslDistro = "Ubuntu-22.04"
)

$ErrorActionPreference = "Stop"

$testbenchDir = "/mnt/c/Users/inseong/.gemini/antigravity/scratch/RV32I-Project/Pipeline/testbench/testbench_LENET"
$wslPath = "/home/inseong/.local/verilator-5.036/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
$imemHex = "../../../FPGA_proj/firmware/lenet_infer_no_cnn_imem.hex"

wsl.exe -d $WslDistro -- bash -lc "export PATH=$wslPath; cd $testbenchDir; make -f Makefile.verilator TIMEOUT_CYCLES=150000000 all"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

for ($digit = 0; $digit -lt 10; $digit++) {
    Write-Host "=== digit$digit ==="
    $cmd = @"
cd $testbenchDir
./obj_dir/VRV32I_System_tb +IMEM_HEX=$imemHex +DMEM_HEX=../../../FPGA_proj/firmware/lenet_digit${digit}_dmem.mem +SAMPLE=digit$digit |
  grep '\[LENET_TB\]\( Done\|\[PERF\]\| sample=\|\[CHECK_FAIL\]\|\[FAIL\]\|\[PASS\]\)'
"@
    wsl.exe -d $WslDistro -- bash -lc $cmd
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
