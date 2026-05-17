# ==========================================
# Vivado Tcl Simulation Script
# ==========================================

puts "\[Tcl\] 1. 임시 시뮬레이션 프로젝트 생성 중..."
# 타겟 보드나 칩 파트 넘버를 적어주세요. (예: xc7a35tcpg236-1)
# -in_memory를 빼고, 'sim_workspace'라는 임시 폴더에 프로젝트를 생성하도록 수정했습니다.
# -force 옵션을 넣으면 스크립트를 다시 실행할 때 기존 폴더를 덮어씁니다.
create_project -force -part xc7a35tcpg236-1 sim_project ./sim_workspace

puts "\[Tcl\] 2. 소스 파일 및 테스트벤치 추가 중..."
# glob를 사용하면 폴더 내의 모든 .v 파일을 한 번에 불러올 수 있습니다.
read_verilog [glob ../../../src/rtl/*.v]
read_verilog [glob ../*.v]

# 테스트벤치가 사용하는 메모리 초기화 파일을 시뮬레이션 파일셋에 포함합니다.
add_files -fileset sim_1 [glob ../*.hex]
set_property file_type {Memory Initialization Files} [get_files [glob ../*.hex]]

# ? 만약 Xilinx IP(.xci)가 있다면 아래 주석을 풀고 사용하세요.
# read_ip ./ip/my_ip/my_ip.xci
# generate_target all [get_ips]

puts "\[Tcl\] 3. Top 모듈 지정..."
# 테스트벤치의 Top 모듈 이름을 정확히 적어야 합니다.
set_property top RV32I_System_tb [get_filesets sim_1]

puts "\[Tcl\] 4. 시뮬레이션 설정..."
# 기본 시뮬레이션 시간은 1000ns입니다. 테스트벤치의 $finish를 만날 때까지
# 끝까지 돌리려면 아래와 같이 runtime을 'all'로 설정합니다.
set_property -name {xsim.simulate.runtime} -value {all} -objects [get_filesets sim_1]

# 순수 RTL 테스트벤치에서는 glbl(기본 1ps timescale) 자동 로드를 끄면
# 의도한 timescale(1ns/1ns)이 전체 시뮬레이션 해상도로 유지됩니다.
set_property -name {xsim.elaborate.load_glbl} -value {false} -objects [get_filesets sim_1]

# 전체 신호 파형 저장은 시뮬레이션을 크게 느리게 하므로 기본값은 비활성화합니다.
# 상세 파형이 필요할 때만 true로 바꿔 사용하세요.
set_property -name {xsim.simulate.log_all_signals} -value {false} -objects [get_filesets sim_1]

puts "\[Tcl\] 5. 컴파일 및 시뮬레이션 실행!"
# launch_simulation 명령어 하나가 컴파일(xvlog) -> 빌드(xelab) -> 실행(xsim)을 모두 자동 수행합니다.
launch_simulation

puts "\[Tcl\] 시뮬레이션 완료!"


