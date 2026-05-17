# ==========================================
# CNN-CFU Integration Test - Vivado Tcl Simulation
# ==========================================

puts "\[Tcl\] 1. 임시 시뮬레이션 프로젝트 생성 중..."
create_project -force -part xc7z020clg400-1 sim_project ./sim_workspace

puts "\[Tcl\] 2. 소스 파일 및 테스트벤치 추가 중..."
# RTL 소스
read_verilog [glob ../../../src/rtl/*.v]
# 테스트벤치
read_verilog ../cnn_integration_tb.v

# HEX 파일 추가
add_files -fileset sim_1 [glob ../*.hex]
set_property file_type {Memory Initialization Files} [get_files [glob ../*.hex]]

puts "\[Tcl\] 3. Top 모듈 지정..."
set_property top cnn_integration_tb [get_filesets sim_1]

puts "\[Tcl\] 4. 시뮬레이션 설정..."
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.load_glbl} -value {false} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {false} -objects [get_filesets sim_1]

puts "\[Tcl\] 5. 컴파일 및 시뮬레이션 실행!"
launch_simulation

puts "\[Tcl\] 시뮬레이션 완료!"
