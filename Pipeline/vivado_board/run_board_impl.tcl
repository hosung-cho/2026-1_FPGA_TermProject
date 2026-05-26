set script_dir [file dirname [info script]]
set root_dir   [file join $script_dir ".." ".."]
set build_dir  [file join $script_dir "build"]
set report_dir [file join $script_dir "reports"]
set part_name  "xc7z020clg484-1"

set xdc_file [file join $script_dir "board.xdc"]
if {![file exists $xdc_file]} {
  puts "ERROR: board.xdc not found."
  puts "Copy board_template.xdc to board.xdc and fill in the real CLOCK_50/reset/LED pins for your board."
  puts "The part number xc7z020clg484-1 is not enough to choose safe physical pins."
  exit 1
}

file mkdir $build_dir
file mkdir $report_dir
cd $script_dir

file copy -force [file join $root_dir "FPGA_proj" "firmware" "lenet_infer_imem.hex"] [file join $script_dir "imem.hex"]
file copy -force [file join $root_dir "FPGA_proj" "firmware" "lenet_digit7_dmem.mem"] [file join $script_dir "lenet_digit7_dmem.mem"]

create_project -force rv32i_lenet_board $build_dir -part $part_name
set_property target_language Verilog [current_project]

read_verilog [file join $root_dir "Pipeline" "src" "rtl" "basic_modules.v"]
read_verilog [file join $root_dir "Pipeline" "src" "rtl" "rv32i_cpu.v"]
read_verilog [file join $root_dir "Pipeline" "src" "rtl" "inst_memory.v"]
read_verilog [file join $root_dir "Pipeline" "src" "rtl" "data_memory.v"]
read_verilog [file join $root_dir "Pipeline" "src" "rtl" "cnn_alu" "mac_pack4_delta.v"]
read_verilog [file join $root_dir "Pipeline" "src" "rtl" "cnn_alu" "CNN_ALU_Top_mac_mdEe.v"]
read_verilog [file join $root_dir "Pipeline" "src" "rtl" "cnn_alu" "CNN_ALU_Top_mux_3bkb.v"]
read_verilog [file join $root_dir "Pipeline" "src" "rtl" "cnn_alu" "CNN_ALU_Top_mux_8cud.v"]
read_verilog [file join $root_dir "Pipeline" "src" "rtl" "cnn_alu" "CNN_ALU_Top.v"]
read_verilog [file join $root_dir "Pipeline" "src" "rtl" "RV32I_System.v"]
read_verilog [file join $root_dir "Pipeline" "src" "rtl" "RV32I_Board_Top.v"]
read_xdc $xdc_file

set synth_status [catch {
  synth_design -top RV32I_Board_Top -part $part_name
} synth_error]
if {$synth_status != 0} {
  if {[llength [get_ports -quiet]] == 0} {
    puts "ERROR: synth_design failed before producing a usable synthesized design."
    puts $synth_error
    exit 1
  }
  puts "WARNING: synth_design returned an error after producing a synthesized design."
  puts "WARNING: Continuing to implementation. Vivado message was:"
  puts $synth_error
}
report_utilization -file [file join $report_dir "post_synth_util.rpt"]
report_timing_summary -file [file join $report_dir "post_synth_timing.rpt"]

opt_design
place_design -directive Explore
phys_opt_design -directive AggressiveExplore
route_design -directive Explore
phys_opt_design -directive AggressiveExplore

report_utilization -file [file join $report_dir "post_route_util.rpt"]
report_timing_summary -file [file join $report_dir "post_route_timing.rpt"]
report_drc -file [file join $report_dir "post_route_drc.rpt"]

set timing_paths [get_timing_paths -max_paths 1 -nworst 1]
set wns [get_property SLACK [lindex $timing_paths 0]]
puts "RV32I_LENET_BOARD_WNS=$wns"
if {$wns < 0} {
  puts "RV32I_LENET_BOARD_TIMING_OK=0"
  exit 2
}
puts "RV32I_LENET_BOARD_TIMING_OK=1"

write_bitstream -force [file join $build_dir "rv32i_lenet_board.bit"]
