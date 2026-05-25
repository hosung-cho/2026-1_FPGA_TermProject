set script_dir [file dirname [info script]]
set root_dir   [file join $script_dir ".." ".."]
set build_dir  "C:/rv32i_lcd_extbram_bd_impl"
set artifact_dir [file join $script_dir "build_ps_lcd_extbram_bd_impl"]
set report_dir [file join $script_dir "reports_ps_lcd_extbram_bd_impl"]
set part_name  "xc7z020clg484-1"
set rv32i_axi_baseaddr "0x43C00000"
set dmem_axi_baseaddr  "0x43C40000"
set lcd_axi_baseaddr   "0x43C80000"
set board_part_name "xilinx.com:zc702:part0:1.1"

file mkdir $build_dir
file mkdir $artifact_dir
file mkdir $report_dir
cd $script_dir

file copy -force [file join $root_dir "FPGA_proj" "firmware" "lenet_infer_imem.hex"] [file join $script_dir "imem.hex"]
file copy -force [file join $root_dir "FPGA_proj" "firmware" "lenet_digit7_dmem.mem"] [file join $script_dir "lenet_digit7_dmem.mem"]

set mem_file [file join $script_dir "lenet_digit7_dmem.mem"]
set coe_file [file join $script_dir "lenet_digit7_dmem.coe"]
set fin [open $mem_file r]
set words [split [read $fin] "\n"]
close $fin
set fout [open $coe_file w]
puts $fout "memory_initialization_radix=16;"
puts $fout "memory_initialization_vector="
set clean_words {}
foreach w $words {
  set t [string trim $w]
  if {$t ne ""} {
    lappend clean_words $t
  }
}
for {set i 0} {$i < [llength $clean_words]} {incr i} {
  set sep ","
  if {$i == ([llength $clean_words] - 1)} {
    set sep ";"
  }
  puts $fout "[lindex $clean_words $i]$sep"
}
close $fout

create_project -force rv32i_lenet_ps_lcd_extbram_bd_impl $build_dir -part $part_name
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
  [file join $root_dir "Pipeline" "src" "rtl" "RV32I_ExternalDmem_System.v"] \
  [file join $root_dir "Pipeline" "src" "rtl" "RV32I_AxiLite_Bram_Top.v"] \
  [file join $root_dir "Pipeline" "src" "rtl" "BramPortA_RunMux.v"] \
  [file join $root_dir "Pipeline" "src" "rtl" "TFTLCD_AxiLite_Top.v"] \
]
add_files -norecurse $rtl_files
add_files -fileset constrs_1 -norecurse [file join $script_dir "tft_lcd.xdc"]
add_files -norecurse [list [file join $script_dir "imem.hex"] $coe_file]
set_property FILE_TYPE {Memory Initialization Files} [get_files [file join $script_dir "imem.hex"]]
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
  CONFIG.PCW_EN_CLK1_PORT {1} \
  CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {25.000000} \
] [get_bd_cells ps7_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property -dict [list CONFIG.NUM_MI {3} CONFIG.NUM_SI {1}] [get_bd_cells axi_interconnect_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_100M
create_bd_cell -type module -reference RV32I_AxiLite_Bram_Top rv32i_bram_axi_0
create_bd_cell -type module -reference TFTLCD_AxiLite_Top tftlcd_axi_0
create_bd_cell -type module -reference BramPortA_RunMux bram_porta_mux_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0
set_property -dict [list CONFIG.DATA_WIDTH {32} CONFIG.SINGLE_PORT_BRAM {1} CONFIG.PROTOCOL {AXI4LITE}] [get_bd_cells axi_bram_ctrl_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_zero_1
set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {0}] [get_bd_cells const_zero_1]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_zero_4
set_property -dict [list CONFIG.CONST_WIDTH {4} CONFIG.CONST_VAL {0}] [get_bd_cells const_zero_4]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_zero_32
set_property -dict [list CONFIG.CONST_WIDTH {32} CONFIG.CONST_VAL {0}] [get_bd_cells const_zero_32]

create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 dmem_bram_0
set_property -dict [list \
  CONFIG.use_bram_block {Stand_Alone} \
  CONFIG.Interface_Type {Native} \
  CONFIG.Memory_Type {True_Dual_Port_RAM} \
  CONFIG.Enable_32bit_Address {false} \
  CONFIG.Use_Byte_Write_Enable {true} \
  CONFIG.Byte_Size {8} \
  CONFIG.Write_Width_A {32} \
  CONFIG.Read_Width_A {32} \
  CONFIG.Write_Depth_A {32768} \
  CONFIG.Write_Width_B {32} \
  CONFIG.Read_Width_B {32} \
  CONFIG.Use_RSTA_Pin {true} \
  CONFIG.Use_RSTB_Pin {true} \
  CONFIG.Enable_A {Use_ENA_Pin} \
  CONFIG.Enable_B {Use_ENB_Pin} \
  CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
  CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
  CONFIG.Load_Init_File {true} \
  CONFIG.Coe_File $coe_file \
] [get_bd_cells dmem_bram_0]

catch {make_bd_intf_pins_external [get_bd_intf_pins ps7_0/DDR]}
catch {make_bd_intf_pins_external [get_bd_intf_pins ps7_0/FIXED_IO]}
create_bd_port -dir O opclk
create_bd_port -dir O Vsync
create_bd_port -dir O Hsync
create_bd_port -dir O -from 4 -to 0 R
create_bd_port -dir O -from 5 -to 0 G
create_bd_port -dir O -from 4 -to 0 B
create_bd_port -dir O TFTLCD_DE_out
create_bd_port -dir O TFTLCD_Tpower

connect_bd_net [get_bd_pins ps7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_pins ps7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_pins ps7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_net [get_bd_pins ps7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_0/M01_ACLK]
connect_bd_net [get_bd_pins ps7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_0/M02_ACLK]
connect_bd_net [get_bd_pins ps7_0/FCLK_CLK0] [get_bd_pins rst_ps7_0_100M/slowest_sync_clk]
connect_bd_net [get_bd_pins ps7_0/FCLK_CLK0] [get_bd_pins rv32i_bram_axi_0/s_axi_aclk]
connect_bd_net [get_bd_pins ps7_0/FCLK_CLK0] [get_bd_pins tftlcd_axi_0/s_axi_aclk]
connect_bd_net [get_bd_pins ps7_0/FCLK_CLK0] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
connect_bd_net [get_bd_pins ps7_0/FCLK_CLK0] [get_bd_pins ps7_0/M_AXI_GP0_ACLK]
connect_bd_net [get_bd_pins ps7_0/FCLK_CLK1] [get_bd_pins tftlcd_axi_0/lcd_clk]

connect_bd_net [get_bd_pins ps7_0/FCLK_RESET0_N] [get_bd_pins rst_ps7_0_100M/ext_reset_in]
connect_bd_net [get_bd_pins rst_ps7_0_100M/interconnect_aresetn] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_pins rst_ps7_0_100M/interconnect_aresetn] [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net [get_bd_pins rst_ps7_0_100M/interconnect_aresetn] [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net [get_bd_pins rst_ps7_0_100M/interconnect_aresetn] [get_bd_pins axi_interconnect_0/M01_ARESETN]
connect_bd_net [get_bd_pins rst_ps7_0_100M/interconnect_aresetn] [get_bd_pins axi_interconnect_0/M02_ARESETN]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins rv32i_bram_axi_0/s_axi_aresetn]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins tftlcd_axi_0/s_axi_aresetn]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]

connect_bd_net [get_bd_pins tftlcd_axi_0/opclk] [get_bd_ports opclk]
connect_bd_net [get_bd_pins tftlcd_axi_0/Vsync] [get_bd_ports Vsync]
connect_bd_net [get_bd_pins tftlcd_axi_0/Hsync] [get_bd_ports Hsync]
connect_bd_net [get_bd_pins tftlcd_axi_0/R] [get_bd_ports R]
connect_bd_net [get_bd_pins tftlcd_axi_0/G] [get_bd_ports G]
connect_bd_net [get_bd_pins tftlcd_axi_0/B] [get_bd_ports B]
connect_bd_net [get_bd_pins tftlcd_axi_0/TFTLCD_DE_out] [get_bd_ports TFTLCD_DE_out]
connect_bd_net [get_bd_pins tftlcd_axi_0/TFTLCD_Tpower] [get_bd_ports TFTLCD_Tpower]

connect_bd_intf_net [get_bd_intf_pins ps7_0/M_AXI_GP0] [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins rv32i_bram_axi_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M01_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M02_AXI] [get_bd_intf_pins tftlcd_axi_0/S_AXI]
connect_bd_net [get_bd_pins rv32i_bram_axi_0/cpu_active] [get_bd_pins bram_porta_mux_0/select_cpu]

connect_bd_net [get_bd_pins axi_bram_ctrl_0/bram_clk_a] [get_bd_pins bram_porta_mux_0/axi_clk]
connect_bd_net [get_bd_pins axi_bram_ctrl_0/bram_rst_a] [get_bd_pins bram_porta_mux_0/axi_rst]
connect_bd_net [get_bd_pins axi_bram_ctrl_0/bram_en_a] [get_bd_pins bram_porta_mux_0/axi_en]
connect_bd_net [get_bd_pins axi_bram_ctrl_0/bram_we_a] [get_bd_pins bram_porta_mux_0/axi_we]
connect_bd_net [get_bd_pins axi_bram_ctrl_0/bram_addr_a] [get_bd_pins bram_porta_mux_0/axi_addr]
connect_bd_net [get_bd_pins axi_bram_ctrl_0/bram_wrdata_a] [get_bd_pins bram_porta_mux_0/axi_din]
connect_bd_net [get_bd_pins axi_bram_ctrl_0/bram_rddata_a] [get_bd_pins bram_porta_mux_0/axi_dout]

connect_bd_net [get_bd_pins rv32i_bram_axi_0/dmem_wr_clk] [get_bd_pins bram_porta_mux_0/cpu_clk]
connect_bd_net [get_bd_pins rv32i_bram_axi_0/dmem_wr_en] [get_bd_pins bram_porta_mux_0/cpu_en]
connect_bd_net [get_bd_pins rv32i_bram_axi_0/dmem_wr_we] [get_bd_pins bram_porta_mux_0/cpu_we]
connect_bd_net [get_bd_pins rv32i_bram_axi_0/dmem_wr_addr] [get_bd_pins bram_porta_mux_0/cpu_addr]
connect_bd_net [get_bd_pins rv32i_bram_axi_0/dmem_wr_din] [get_bd_pins bram_porta_mux_0/cpu_din]

connect_bd_net [get_bd_pins bram_porta_mux_0/bram_clk] [get_bd_pins dmem_bram_0/clka]
connect_bd_net [get_bd_pins bram_porta_mux_0/bram_rst] [get_bd_pins dmem_bram_0/rsta]
connect_bd_net [get_bd_pins bram_porta_mux_0/bram_en] [get_bd_pins dmem_bram_0/ena]
connect_bd_net [get_bd_pins bram_porta_mux_0/bram_we] [get_bd_pins dmem_bram_0/wea]
connect_bd_net [get_bd_pins bram_porta_mux_0/bram_addr] [get_bd_pins dmem_bram_0/addra]
connect_bd_net [get_bd_pins bram_porta_mux_0/bram_din] [get_bd_pins dmem_bram_0/dina]
connect_bd_net [get_bd_pins bram_porta_mux_0/bram_dout] [get_bd_pins dmem_bram_0/douta]

connect_bd_net [get_bd_pins rv32i_bram_axi_0/dmem_rd_clk] [get_bd_pins dmem_bram_0/clkb]
connect_bd_net [get_bd_pins rv32i_bram_axi_0/dmem_rd_en] [get_bd_pins dmem_bram_0/enb]
connect_bd_net [get_bd_pins rv32i_bram_axi_0/dmem_rd_addr] [get_bd_pins dmem_bram_0/addrb]
connect_bd_net [get_bd_pins rv32i_bram_axi_0/dmem_rd_dout] [get_bd_pins dmem_bram_0/doutb]
connect_bd_net [get_bd_pins const_zero_1/dout] [get_bd_pins dmem_bram_0/rstb]
connect_bd_net [get_bd_pins const_zero_4/dout] [get_bd_pins dmem_bram_0/web]
connect_bd_net [get_bd_pins const_zero_32/dout] [get_bd_pins dmem_bram_0/dinb]

assign_bd_address
set rv32i_seg [get_bd_addr_segs -quiet ps7_0/Data/SEG_rv32i_bram_axi_0_reg0]
set dmem_seg [get_bd_addr_segs -quiet ps7_0/Data/SEG_axi_bram_ctrl_0_Mem0]
set lcd_seg [get_bd_addr_segs -quiet ps7_0/Data/SEG_tftlcd_axi_0_reg0]
if {[llength $rv32i_seg] == 0 || [llength $dmem_seg] == 0 || [llength $lcd_seg] == 0} {
  puts "ERROR: expected AXI address segments were not created."
  exit 1
}
set_property offset $rv32i_axi_baseaddr $rv32i_seg
set_property range 64K $rv32i_seg
set_property offset $dmem_axi_baseaddr $dmem_seg
set_property range 128K $dmem_seg
set_property offset $lcd_axi_baseaddr $lcd_seg
set_property range 512K $lcd_seg

set_property -dict [list \
  CONFIG.use_bram_block {Stand_Alone} \
  CONFIG.Write_Depth_A {32768} \
  CONFIG.Read_Width_A {32} \
  CONFIG.Write_Width_A {32} \
  CONFIG.Read_Width_B {32} \
  CONFIG.Write_Width_B {32} \
  CONFIG.Use_RSTA_Pin {true} \
  CONFIG.Use_RSTB_Pin {true} \
  CONFIG.Enable_A {Use_ENA_Pin} \
  CONFIG.Enable_B {Use_ENB_Pin} \
] [get_bd_cells dmem_bram_0]

validate_bd_design
save_bd_design
generate_target all [get_files [file join $build_dir "rv32i_lenet_ps_lcd_extbram_bd_impl.srcs" "sources_1" "bd" "design_1" "design_1.bd"]]
set wrapper_file [make_wrapper -files [get_files [file join $build_dir "rv32i_lenet_ps_lcd_extbram_bd_impl.srcs" "sources_1" "bd" "design_1" "design_1.bd"]] -top]
add_files -norecurse $wrapper_file
set_property top design_1_wrapper [current_fileset]
update_compile_order -fileset sources_1

proc try_set_run_property {prop value run_name} {
  if {[catch {set_property $prop $value [get_runs $run_name]} msg]} {
    puts "WARNING: could not set $run_name $prop=$value"
    puts $msg
  }
}

try_set_run_property strategy Flow_PerfOptimized_high synth_1
try_set_run_property strategy Performance_Explore impl_1
try_set_run_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore impl_1
try_set_run_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE ExtraNetDelay_high impl_1
try_set_run_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true impl_1
try_set_run_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore impl_1
try_set_run_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE Explore impl_1
try_set_run_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true impl_1
try_set_run_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore impl_1

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
report_utilization -file [file join $report_dir "ps_lcd_extbram_bd_post_route_util.rpt"]
report_timing_summary -file [file join $report_dir "ps_lcd_extbram_bd_post_route_timing.rpt"]
report_drc -file [file join $report_dir "ps_lcd_extbram_bd_post_route_drc.rpt"]

set timing_paths [get_timing_paths -max_paths 1 -nworst 1]
set wns [get_property SLACK [lindex $timing_paths 0]]
puts "RV32I_PS_LCD_EXTBRAM_BD_WNS=$wns"
if {$wns < 0} {
  puts "RV32I_PS_LCD_EXTBRAM_BD_TIMING_OK=0"
  exit 2
}
puts "RV32I_PS_LCD_EXTBRAM_BD_TIMING_OK=1"

set bit_file [file join $build_dir "rv32i_lenet_ps_lcd_extbram_bd_impl.runs" "impl_1" "design_1_wrapper.bit"]
file copy -force $bit_file [file join $artifact_dir "rv32i_lenet_ps_lcd_extbram_bd.bit"]
write_hwdef -force -file [file join $artifact_dir "rv32i_lenet_ps_lcd_extbram_bd.hdf"]

puts "RV32I_PS_LCD_EXTBRAM_BD_IMPL_OK=1"
puts "RV32I_AXI_BASEADDR=[get_property OFFSET $rv32i_seg]"
puts "DMEM_AXI_BASEADDR=[get_property OFFSET $dmem_seg]"
puts "TFTLCD_AXI_BASEADDR=[get_property OFFSET $lcd_seg]"
puts "RV32I_PS_LCD_EXTBRAM_BD_BIT=[file join $artifact_dir rv32i_lenet_ps_lcd_extbram_bd.bit]"
puts "RV32I_PS_LCD_EXTBRAM_BD_HDF=[file join $artifact_dir rv32i_lenet_ps_lcd_extbram_bd.hdf]"
