set script_dir [file dirname [info script]]
set root_dir   [file join $script_dir ".." ".."]
set build_dir  [file join $script_dir "build_ps_sample"]
set report_dir [file join $script_dir "reports_ps_sample"]
set part_name  "xc7z020clg484-1"
set expected_axi_baseaddr "0x43C00000"
set board_part_name "xilinx.com:zc702:part0:1.1"

file mkdir $build_dir
file mkdir $report_dir
cd $script_dir

file copy -force [file join $root_dir "FPGA_proj" "firmware" "lenet_infer_imem.hex"] [file join $script_dir "imem.hex"]
file copy -force [file join $root_dir "FPGA_proj" "firmware" "lenet_digit7_dmem.mem"] [file join $script_dir "lenet_digit7_dmem.mem"]

create_project -force rv32i_sp $build_dir -part $part_name
set_property target_language Verilog [current_project]
if {[llength [get_board_parts -quiet $board_part_name]] != 0} {
  set_property board_part $board_part_name [current_project]
} else {
  puts "WARNING: board_part $board_part_name not installed; using part-only PS settings."
}

set rtl_files [list \
  [file join $root_dir "Pipeline" "src" "rtl" "basic_modules.v"] \
  [file join $root_dir "Pipeline" "src" "rtl" "rv32i_cpu.v"] \
  [file join $root_dir "Pipeline" "src" "rtl" "inst_memory.v"] \
  [file join $root_dir "Pipeline" "src" "rtl" "cnn_alu" "mac_pack4_delta.v"] \
  [file join $root_dir "Pipeline" "src" "rtl" "cnn_alu" "CNN_ALU_Top_mac_mdEe.v"] \
  [file join $root_dir "Pipeline" "src" "rtl" "cnn_alu" "CNN_ALU_Top_mux_3bkb.v"] \
  [file join $root_dir "Pipeline" "src" "rtl" "cnn_alu" "CNN_ALU_Top_mux_8cud.v"] \
  [file join $root_dir "Pipeline" "src" "rtl" "cnn_alu" "CNN_ALU_Top.v"] \
  [file join $root_dir "Pipeline" "src" "rtl" "RV32I_AxiLite_Sample_Top.v"] \
]
add_files -norecurse $rtl_files
update_compile_order -fileset sources_1

create_bd_design "design_1"

create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7_0
set ps_auto_status [catch {
  apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable"} \
    [get_bd_cells ps7_0]
} ps_auto_msg]
if {$ps_auto_status != 0} {
  puts "WARNING: PS7 board automation failed; falling back to explicit PS7 settings."
  puts $ps_auto_msg
}
set_property -dict [list \
  CONFIG.PCW_USE_M_AXI_GP0 {1} \
  CONFIG.PCW_EN_CLK0_PORT {1} \
  CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100.000000} \
] [get_bd_cells ps7_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property -dict [list CONFIG.NUM_MI {1} CONFIG.NUM_SI {1}] [get_bd_cells axi_interconnect_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_100M
create_bd_cell -type module -reference RV32I_AxiLite_Sample_Top rv32i_sample_axi_0

catch {make_bd_intf_pins_external [get_bd_intf_pins ps7_0/DDR]}
catch {make_bd_intf_pins_external [get_bd_intf_pins ps7_0/FIXED_IO]}

connect_bd_net [get_bd_pins ps7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_pins ps7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_pins ps7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_net [get_bd_pins ps7_0/FCLK_CLK0] [get_bd_pins rst_ps7_0_100M/slowest_sync_clk]
connect_bd_net [get_bd_pins ps7_0/FCLK_CLK0] [get_bd_pins rv32i_sample_axi_0/s_axi_aclk]
connect_bd_net [get_bd_pins ps7_0/FCLK_CLK0] [get_bd_pins ps7_0/M_AXI_GP0_ACLK]

connect_bd_net [get_bd_pins ps7_0/FCLK_RESET0_N] [get_bd_pins rst_ps7_0_100M/ext_reset_in]
connect_bd_net [get_bd_pins rst_ps7_0_100M/interconnect_aresetn] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_pins rst_ps7_0_100M/interconnect_aresetn] [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net [get_bd_pins rst_ps7_0_100M/interconnect_aresetn] [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins rv32i_sample_axi_0/s_axi_aresetn]

connect_bd_intf_net [get_bd_intf_pins ps7_0/M_AXI_GP0] [get_bd_intf_pins axi_interconnect_0/S00_AXI]

set rv32i_axi_intf [get_bd_intf_pins -quiet rv32i_sample_axi_0/S_AXI]
if {[llength $rv32i_axi_intf] == 0} {
  set rv32i_axi_intf [get_bd_intf_pins -quiet rv32i_sample_axi_0/s_axi]
}
if {[llength $rv32i_axi_intf] == 0} {
  puts "ERROR: RV32I_AxiLite_Sample_Top AXI interface was not inferred by Vivado."
  exit 1
}
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] $rv32i_axi_intf

assign_bd_address
set rv32i_seg [get_bd_addr_segs -quiet ps7_0/Data/SEG_rv32i_sample_axi_0_reg0]
if {[llength $rv32i_seg] == 0} {
  puts "ERROR: RV32I sample AXI address segment was not created."
  exit 1
}
set_property offset $expected_axi_baseaddr $rv32i_seg
set_property range 16K $rv32i_seg

set actual_axi_baseaddr [get_property OFFSET $rv32i_seg]
if {$actual_axi_baseaddr ne $expected_axi_baseaddr} {
  puts "ERROR: RV32I sample AXI base address mismatch. expected=$expected_axi_baseaddr actual=$actual_axi_baseaddr"
  exit 1
}

validate_bd_design
save_bd_design
generate_target all [get_files [file join $build_dir "rv32i_sp.srcs" "sources_1" "bd" "design_1" "design_1.bd"]]

set wrapper_file [make_wrapper -files [get_files [file join $build_dir "rv32i_sp.srcs" "sources_1" "bd" "design_1" "design_1.bd"]] -top]
add_files -norecurse $wrapper_file
set_property top design_1_wrapper [current_fileset]
update_compile_order -fileset sources_1

launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
  puts "ERROR: impl_1 did not complete"
  exit 1
}
if {[get_property STATUS [get_runs impl_1]] != "write_bitstream Complete!"} {
  puts "ERROR: impl_1 status is [get_property STATUS [get_runs impl_1]]"
  exit 1
}

open_run impl_1
report_utilization -file [file join $report_dir "ps_sample_post_route_util.rpt"]
report_timing_summary -file [file join $report_dir "ps_sample_post_route_timing.rpt"]
report_drc -file [file join $report_dir "ps_sample_post_route_drc.rpt"]

set timing_paths [get_timing_paths -max_paths 1 -nworst 1]
set wns [get_property SLACK [lindex $timing_paths 0]]
puts "RV32I_PS_SAMPLE_BD_WNS=$wns"
if {$wns < 0} {
  puts "RV32I_PS_SAMPLE_BD_TIMING_OK=0"
  exit 2
}
puts "RV32I_PS_SAMPLE_BD_TIMING_OK=1"

set bit_file [file join $build_dir "rv32i_sp.runs" "impl_1" "design_1_wrapper.bit"]
file copy -force $bit_file [file join $build_dir "rv32i_lenet_ps_sample_bd.bit"]
write_hwdef -force -file [file join $build_dir "rv32i_lenet_ps_sample_bd.hdf"]

puts "RV32I_PS_SAMPLE_BD_IMPL_OK=1"
puts "RV32I_AXI_BASEADDR=$actual_axi_baseaddr"
puts "RV32I_SAMPLE_REG_OFFSET=0x0000"
puts "RV32I_SAMPLE_INPUT_OFFSET=0x1000"
puts "RV32I_SAMPLE_EXPECTED_OFFSET=0x2000"
puts "RV32I_PS_SAMPLE_BD_BIT=[file join $build_dir rv32i_lenet_ps_sample_bd.bit]"
puts "RV32I_PS_SAMPLE_BD_HDF=[file join $build_dir rv32i_lenet_ps_sample_bd.hdf]"
