# ==============================================================================
# Phase Shift (CPU: 0도, IMEM: 90도, DMEM: 180도~210도) 최적화 XDC 제약
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. IMEM (50MHz, 90도/5ns) -> CPU (50MHz, 0도/20ns) 경로
# ------------------------------------------------------------------------------
# 5ns에 출발한 명령어가 20ns 레지스터 파일에 도달하는 경로입니다 (여유: 15ns).
# Vivado가 홀드(Hold) 검사 기준점을 0ns(과거)로 잡아 발생하는 오해를 방지하고,
# 실제 데이터가 출발하는 5ns 시점을 기준으로 홀드를 검사하도록 고정합니다.
set_multicycle_path -setup -from [get_clocks clk_imem_design_1_clk_wiz_0_0] -to [get_clocks clk_cpu_design_1_clk_wiz_0_0] 1
set_multicycle_path -hold  -from [get_clocks clk_imem_design_1_clk_wiz_0_0] -to [get_clocks clk_cpu_design_1_clk_wiz_0_0] 0


# ------------------------------------------------------------------------------
# 2. DMEM (50MHz, 180도/10ns) -> CPU (50MHz, 0도/20ns) 경로 (★가장 중요)
# ------------------------------------------------------------------------------
# 10ns에 출발한 데이터가 20ns 레지스터 파일에 "무조건" 도달해야 하는 경로입니다 (여유: 10ns).
# 단일 사이클 CPU 특성상 이 절대적인 시간 마진(10ns) 내에 배선이 완료되어야 하므로, 
# 셋업 사이클을 뒤로 미루지 않고 '1'로 고정하여 20ns 엣지에 강제 안착하도록 만듭니다.
# 홀드 기준점 역시 데이터가 출발하는 10ns 시점으로 고정하기 위해 '0'을 줍니다.
set_multicycle_path -setup -from [get_clocks clk_dmem_design_1_clk_wiz_0_0] -to [get_clocks clk_cpu_design_1_clk_wiz_0_0] 1
set_multicycle_path -hold  -from [get_clocks clk_dmem_design_1_clk_wiz_0_0] -to [get_clocks clk_cpu_design_1_clk_wiz_0_0] 0
