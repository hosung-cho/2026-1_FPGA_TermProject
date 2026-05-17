# ==========================================
# CNN-CFU Unit Test - Vivado Tcl Simulation
# ==========================================

puts "\[Tcl\] 1. 임시 시뮬레이션 프로젝트 생성 중..."
create_project -force -part xc7z020clg400-1 sim_project ./sim_workspace

puts "\[Tcl\] 2. 소스 파일 및 테스트벤치 추가 중..."
# CFU RTL 소스
read_verilog ../../../src/rtl/cnn_cfu.v
# 테스트벤치
read_verilog ../cnn_cfu_tb.v

puts "\[Tcl\] 3. Top 모듈 지정..."
set_property top cnn_cfu_tb [get_filesets sim_1]

puts "\[Tcl\] 4. 시뮬레이션 설정..."
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.load_glbl} -value {false} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {false} -objects [get_filesets sim_1]

puts "\[Tcl\] 5. 컴파일 및 시뮬레이션 실행!"
launch_simulation

puts "\[Tcl\] 시뮬레이션 완료!"
