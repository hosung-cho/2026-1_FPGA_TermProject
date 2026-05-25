connect -url tcp:127.0.0.1:3121
puts "RV32I_LCD_XSDB_TARGETS_BEGIN"
targets
puts "RV32I_LCD_XSDB_TARGETS_END"

targets -set -filter {name =~ "ARM Cortex-A9 MPCore #0"}
memmap -addr 0x43C00000 -size 0x10000 -flags 3
memmap -addr 0x43C80000 -size 0x80000 -flags 3

source C:/rv32i_lcd_bd_impl/rv32i_lenet_ps_lcd_bd_impl.srcs/sources_1/bd/design_1/ip/design_1_ps7_0_0/ps7_init.tcl
ps7_init
ps7_post_config

set rv_base 0x43C00000
set reg_control [expr {$rv_base + 0x00}]
set reg_status  [expr {$rv_base + 0x04}]
set reg_pred    [expr {$rv_base + 0x08}]
set reg_exp     [expr {$rv_base + 0x0C}]
set reg_hb      [expr {$rv_base + 0x10}]
set reg_pc      [expr {$rv_base + 0x14}]

set lcd_base 0x43C80000
set lcd_width 480
set lcd_height 272
set bar_width 120

proc write_run {addr value count} {
  mwr -force $addr $value $count
}

puts "TFTLCD_COLORBARS_BEGIN=1"
for {set y 0} {$y < $lcd_height} {incr y} {
  set row [expr {$lcd_base + ($y * $lcd_width * 4)}]
  write_run $row 0x0000F800 $bar_width
  write_run [expr {$row + ($bar_width * 4)}] 0x000007E0 $bar_width
  write_run [expr {$row + ($bar_width * 8)}] 0x0000001F $bar_width
  write_run [expr {$row + ($bar_width * 12)}] 0x0000FFFF $bar_width
}
puts "TFTLCD_COLORBARS_WRITTEN=1"
puts "TFTLCD_AXI_BASEADDR=0x43C80000"

mwr -force $reg_control 0x00000002
mwr -force $reg_control 0x00000001

set status 0
for {set i 0} {$i < 200} {incr i} {
  after 100
  set status_line [mrd -force $reg_status]
  regexp {:\s+([0-9A-Fa-f]+)} $status_line -> status_hex
  scan $status_hex %x status
  if {($status & 0x1) != 0} {
    break
  }
}

puts "RV32I_STATUS_RAW=[mrd -force $reg_status]"
puts "RV32I_PRED_RAW=[mrd -force $reg_pred]"
puts "RV32I_EXPECTED_RAW=[mrd -force $reg_exp]"
puts "RV32I_HEARTBEAT_RAW=[mrd -force $reg_hb]"
puts "RV32I_PC_RAW=[mrd -force $reg_pc]"

if {($status & 0x3) == 0x3} {
  puts "RV32I_XSDB_PASS=1"
} else {
  puts "RV32I_XSDB_PASS=0"
}

disconnect
