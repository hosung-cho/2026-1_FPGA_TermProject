# ========================================================
# 1. 가는 길 (CPU -> BRAM) : 50MHz -> 200MHz (기존 코드 유지)
# ========================================================
set_multicycle_path -setup -from [get_clocks clk_50_design_1_clk_wiz_0_1] -to [get_clocks clk_200_design_1_clk_wiz_0_1] 4
set_multicycle_path -hold -from [get_clocks clk_50_design_1_clk_wiz_0_1] -to [get_clocks clk_200_design_1_clk_wiz_0_1] 3

# ========================================================
# 2. 오는 길 (BRAM -> CPU) : 200MHz -> 50MHz (새로 추가할 코드)
# ========================================================
set_multicycle_path -setup -start -from [get_clocks clk_200_design_1_clk_wiz_0_1] -to [get_clocks clk_50_design_1_clk_wiz_0_1] 4
set_multicycle_path -hold -start -from [get_clocks clk_200_design_1_clk_wiz_0_1] -to [get_clocks clk_50_design_1_clk_wiz_0_1] 3

# ========================================================
# 3. 내부 연산 길 (IMEM -> ALU -> DMEM) : 200MHz -> 200MHz (★새로 추가)
# ========================================================
set_multicycle_path -setup -from [get_clocks clk_200_design_1_clk_wiz_0_1] -to [get_clocks clk_200_design_1_clk_wiz_0_1] 4
set_multicycle_path -hold -from [get_clocks clk_200_design_1_clk_wiz_0_1] -to [get_clocks clk_200_design_1_clk_wiz_0_1] 3