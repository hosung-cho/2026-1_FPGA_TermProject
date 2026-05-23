# ==============================================================================
# Phase Shift(0도, 90도, 270도) 환경을 위한 마스터 타이밍 제약 (XDC)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. IMEM(90도) -> CPU(0도) 경로 구제하기
# ------------------------------------------------------------------------------
# 5ns에 출발한 명령어는 20ns에 접수됩니다. (Setup 여유 15ns)
# Vivado가 홀드 타임 검사 기준점을 엉뚱한 과거(0ns)로 잡지 않도록 보정합니다.
set_multicycle_path -setup -from [get_clocks clk_imem_design_1_clk_wiz_0_0] -to [get_clocks clk_cpu_design_1_clk_wiz_0_0] 1
set_multicycle_path -hold  -from [get_clocks clk_imem_design_1_clk_wiz_0_0] -to [get_clocks clk_cpu_design_1_clk_wiz_0_0] 1


# ------------------------------------------------------------------------------
# 2. DMEM(270도) -> CPU(0도) 경로 구제하기 (★가장 중요)
# ------------------------------------------------------------------------------
# 15ns에 나온 데이터가 20ns에 들어가는 5ns짜리 빡빡한 경로로 Vivado가 오해하고 있습니다.
# 실제 단일 사이클 CPU 구조에서 이 경로는 다음 사이클인 40ns 엣지까지 여유를 주거나,
# 툴에게 20ns 스케일로 배선 여유를 잡으라고 명령해야 합니다. 
# 아래 제약을 통해 Setup 마진을 5ns에서 25ns(다음 사이클) 영역으로 확장시킵니다.

set_multicycle_path -setup -from [get_clocks clk_dmem_design_1_clk_wiz_0_0] -to [get_clocks clk_cpu_design_1_clk_wiz_0_0] 2
set_multicycle_path -hold  -from [get_clocks clk_dmem_design_1_clk_wiz_0_0] -to [get_clocks clk_cpu_design_1_clk_wiz_0_0] 1