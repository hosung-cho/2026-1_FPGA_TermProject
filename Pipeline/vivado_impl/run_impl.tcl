set script_dir [file dirname [file normalize [info script]]]
set root_dir [file normalize [file join $script_dir "../.."]]
set build_dir [file normalize [file join $script_dir "build"]]
set report_dir [file normalize [file join $script_dir "reports"]]

file mkdir $build_dir
file mkdir $report_dir
cd $script_dir

create_project -force rv32i_lenet_impl $build_dir -part xc7z020clg484-1
set_property target_language Verilog [current_project]

file copy -force [file join $root_dir "FPGA_proj/firmware/lenet_infer_imem.hex"] [file join $script_dir "imem.hex"]

set rtl_dir [file join $root_dir "Pipeline/src/rtl"]
set cnn_dir [file join $rtl_dir "cnn_alu"]

read_verilog [file join $rtl_dir "basic_modules.v"]
read_verilog [file join $rtl_dir "rv32i_cpu.v"]
read_verilog [file join $rtl_dir "inst_memory.v"]
read_verilog [file join $rtl_dir "data_memory.v"]
foreach vf [glob -nocomplain [file join $cnn_dir "*.v"]] {
    read_verilog $vf
}
read_verilog [file join $rtl_dir "RV32I_System.v"]

set top_name RV32I_System

synth_design -top $top_name -part xc7z020clg484-1 -flatten_hierarchy none
create_clock -name clk_100m -period 10.000 [get_ports CLOCK_50]
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
write_checkpoint -force [file join $report_dir "post_synth.dcp"]
report_utilization -file [file join $report_dir "post_synth_util.rpt"]
report_utilization -hierarchical -file [file join $report_dir "post_synth_util_hier.rpt"]
report_timing_summary -delay_type max -max_paths 20 -file [file join $report_dir "post_synth_timing.rpt"]

opt_design -directive Explore
place_design -directive Explore
phys_opt_design -directive AggressiveExplore
route_design -directive Explore
phys_opt_design -directive AggressiveExplore

write_checkpoint -force [file join $report_dir "post_route.dcp"]
report_utilization -file [file join $report_dir "post_route_util.rpt"]
report_utilization -hierarchical -file [file join $report_dir "post_route_util_hier.rpt"]
report_timing_summary -delay_type max -max_paths 20 -file [file join $report_dir "post_route_timing.rpt"]
report_drc -file [file join $report_dir "post_route_drc.rpt"]

set timing_ok [expr {[get_property SLACK [get_timing_paths -max_paths 1 -delay_type max]] >= 0}]
puts "RV32I_LENET_IMPL_TIMING_OK=$timing_ok"
