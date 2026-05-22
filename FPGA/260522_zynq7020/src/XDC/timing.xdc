# ========================================================
# 1. 가는 길 (CPU -> BRAM) : 50MHz -> 150MHz
# (0ns 출발 -> 20ns(3번째 엣지) 전에 도착해야 함)
# ========================================================
set_multicycle_path -setup -from [get_clocks clk_cpu_design_1_clk_wiz_0_0] -to [get_clocks clk_bram_design_1_clk_wiz_0_0] 3
set_multicycle_path -hold  -from [get_clocks clk_cpu_design_1_clk_wiz_0_0] -to [get_clocks clk_bram_design_1_clk_wiz_0_0] 2

# ========================================================
# 2. 오는 길 (BRAM -> CPU) : 150MHz -> 50MHz
# (13.33ns(2번째 엣지)에서 출발 -> 20ns CPU 엣지 전에 도착해야 함)
# ========================================================
set_multicycle_path -setup -start -from [get_clocks clk_bram_design_1_clk_wiz_0_0] -to [get_clocks clk_cpu_design_1_clk_wiz_0_0] 3
set_multicycle_path -hold  -start -from [get_clocks clk_bram_design_1_clk_wiz_0_0] -to [get_clocks clk_cpu_design_1_clk_wiz_0_0] 2

# ========================================================
# 3. 내부 연산 길 (IMEM -> ALU -> DMEM) : 150MHz -> 150MHz
# (6.66ns 출발 -> 13.33ns 도착 = 정확히 1사이클 소요)
# ※ 1사이클은 Vivado의 기본 동작이므로 별도의 멀티사이클 제약이 필요 없음!
# ========================================================
# set_multicycle_path ... (해당 줄 삭제 또는 주석 처리)