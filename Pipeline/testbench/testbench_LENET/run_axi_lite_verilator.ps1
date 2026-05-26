param(
    [string]$WslDistro = "Ubuntu-22.04"
)

$ErrorActionPreference = "Stop"

$testbenchDir = "/mnt/c/Users/inseong/.gemini/antigravity/scratch/RV32I-Project/.worktree-inseong/Pipeline/testbench/testbench_LENET"
$wslPath = "/home/inseong/.local/verilator-5.036/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

$cmd = @"
export PATH=$wslPath
cd $testbenchDir
make -f Makefile.axi_verilator run RUN_ARGS='+IMEM_HEX=../../../FPGA_proj/firmware/lenet_infer_imem.hex +DMEM_HEX=../../../FPGA_proj/firmware/lenet_digit7_dmem.mem' |
  grep '\[AXI_TB\]\( Done\| status=\|\[CHECK_FAIL\]\|\[FAIL\]\|\[PASS\]\)'
"@

wsl.exe -d $WslDistro -- bash -lc $cmd
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
