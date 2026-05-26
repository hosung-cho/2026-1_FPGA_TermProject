set script_dir [file dirname [info script]]
set bit_file [file join $script_dir "build_ps_lcd_extbram_cycle_bd_impl" "rv32i_lenet_ps_lcd_extbram_bd.bit"]

if {![file exists $bit_file]} {
  puts "ERROR: extbram cycle-counter bitstream not found: $bit_file"
  exit 1
}

open_hw
connect_hw_server
open_hw_target

set devices [get_hw_devices]
puts "RV32I_LCD_EXTBRAM_CYCLE_HW_DEVICES=$devices"

set zynq_device [lindex [get_hw_devices -quiet xc7z020*] 0]
if {$zynq_device eq ""} {
  set zynq_device [lindex [get_hw_devices -quiet *7z020*] 0]
}
if {$zynq_device eq ""} {
  puts "ERROR: xc7z020 device not found over JTAG."
  exit 1
}

current_hw_device $zynq_device
refresh_hw_device -update_hw_probes false $zynq_device
set_property PROGRAM.FILE $bit_file $zynq_device
program_hw_devices $zynq_device
refresh_hw_device -update_hw_probes false $zynq_device

puts "RV32I_LCD_EXTBRAM_CYCLE_PROGRAM_OK=1"
puts "RV32I_LCD_EXTBRAM_CYCLE_PROGRAMMED_DEVICE=$zynq_device"
puts "RV32I_LCD_EXTBRAM_CYCLE_PROGRAMMED_BIT=$bit_file"
