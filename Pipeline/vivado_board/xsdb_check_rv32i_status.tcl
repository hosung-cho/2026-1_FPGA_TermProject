connect -url tcp:127.0.0.1:3121
puts "RV32I_XSDB_TARGETS_BEGIN"
targets
puts "RV32I_XSDB_TARGETS_END"

targets -set -filter {name =~ "ARM Cortex-A9 MPCore #0"}
memmap -addr 0x43C00000 -size 0x10000 -flags 3

source ./build_ps_bd_impl/rv32i_lenet_ps_bd_impl.srcs/sources_1/bd/design_1/ip/design_1_ps7_0_0/ps7_init.tcl
ps7_init
ps7_post_config

set base 0x43C00000
set reg_control [expr {$base + 0x00}]
set reg_status  [expr {$base + 0x04}]
set reg_pred    [expr {$base + 0x08}]
set reg_exp     [expr {$base + 0x0C}]
set reg_hb      [expr {$base + 0x10}]
set reg_pc      [expr {$base + 0x14}]

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
