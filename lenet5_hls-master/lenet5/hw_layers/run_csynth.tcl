open_project cnn_alu_hls_prj
set_top CNN_ALU_Top
add_files cnn_alu.cpp -cflags "-I."
add_files -tb tb_cnn_alu.cpp -cflags "-I."
open_solution "solution1"
set_part {xc7z020clg484-1}
create_clock -period 10 -name default
csynth_design
exit
