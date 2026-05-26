connect -url tcp:127.0.0.1:3121
targets -set -filter {name =~ "ARM Cortex-A9 MPCore #0"}
memmap -addr 0x43C00000 -size 0x10000 -flags 3
memmap -addr 0x43C40000 -size 0x20000 -flags 3
memmap -addr 0x43C80000 -size 0x80000 -flags 3

set script_dir [file dirname [info script]]
set repo_root [file normalize [file join $script_dir ".." ".."]]
set ps7_init_file "C:/rv32i_lcd_extbram_cycle_bd_impl/rv32i_lenet_ps_lcd_extbram_bd_impl.srcs/sources_1/bd/design_1/ip/design_1_ps7_0_0/ps7_init.tcl"
set dmem_dir [file normalize [file join $repo_root "FPGA_proj" "firmware"]]

if {![file exists $ps7_init_file]} {
  puts "ERROR: ps7_init.tcl not found: $ps7_init_file"
  disconnect
  exit 1
}

source $ps7_init_file
ps7_init
ps7_post_config

set rv_base 0x43C00000
set dmem_base 0x43C40000
set lcd_base 0x43C80000
set reg_control [expr {$rv_base + 0x00}]
set reg_status  [expr {$rv_base + 0x04}]
set reg_pred    [expr {$rv_base + 0x08}]
set reg_exp     [expr {$rv_base + 0x0C}]
set reg_hb      [expr {$rv_base + 0x10}]
set reg_pc      [expr {$rv_base + 0x14}]
set reg_data_addr [expr {$rv_base + 0x1C}]
set reg_read_data [expr {$rv_base + 0x20}]
set reg_cycle_count [expr {$rv_base + 0x2C}]

set repeat_count 1
if {[llength $argv] >= 1} {
  set repeat_count [lindex $argv 0]
}
if {$repeat_count < 1} {
  set repeat_count 1
}
set digit_start 0
set digit_end 9
if {[llength $argv] >= 2} {
  set digit_start [lindex $argv 1]
}
if {[llength $argv] >= 3} {
  set digit_end [lindex $argv 2]
}
if {$digit_start < 0} {
  set digit_start 0
}
if {$digit_end > 9} {
  set digit_end 9
}
if {$digit_end < $digit_start} {
  set digit_end $digit_start
}

proc read_word {addr} {
  set line [mrd -force $addr]
  regexp {:\s+([0-9A-Fa-f]+)} $line -> hex
  scan $hex %x value
  return $value
}

proc fill_rect {base width x y w h color} {
  for {set row 0} {$row < $h} {incr row} {
    set addr [expr {$base + (($y + $row) * $width + $x) * 4}]
    mwr -force $addr $color $w
  }
}

proc draw_digit7seg {base width x y scale digit color dim_color} {
  set t [expr {8 * $scale}]
  set l [expr {46 * $scale}]
  set v [expr {70 * $scale}]
  set gap [expr {6 * $scale}]
  set w [expr {$l + (2 * $t) + (2 * $gap)}]
  set h [expr {(2 * $v) + (3 * $t) + (4 * $gap)}]

  fill_rect $base $width $x $y $w $h 0x00001863

  array set map {
    0 {1 1 1 1 1 1 0}
    1 {0 1 1 0 0 0 0}
    2 {1 1 0 1 1 0 1}
    3 {1 1 1 1 0 0 1}
    4 {0 1 1 0 0 1 1}
    5 {1 0 1 1 0 1 1}
    6 {1 0 1 1 1 1 1}
    7 {1 1 1 0 0 0 0}
    8 {1 1 1 1 1 1 1}
    9 {1 1 1 1 0 1 1}
  }
  if {![info exists map($digit)]} {
    set digit 0
  }
  set segs $map($digit)

  set xa [expr {$x + $t + $gap}]
  set ya [expr {$y + $gap}]
  set xd $xa
  set yd [expr {$y + (2 * $v) + (2 * $t) + (3 * $gap)}]
  set xg $xa
  set yg [expr {$y + $v + $t + (2 * $gap)}]
  set xb [expr {$x + $t + $l + (2 * $gap)}]
  set yb [expr {$y + $t + (2 * $gap)}]
  set xc $xb
  set yc [expr {$y + $v + (2 * $t) + (3 * $gap)}]
  set xf [expr {$x + $gap}]
  set yf $yb
  set xe $xf
  set ye $yc

  set coords [list \
    [list $xa $ya $l $t] \
    [list $xb $yb $t $v] \
    [list $xc $yc $t $v] \
    [list $xd $yd $l $t] \
    [list $xe $ye $t $v] \
    [list $xf $yf $t $v] \
    [list $xg $yg $l $t]]

  for {set i 0} {$i < 7} {incr i} {
    set c $dim_color
    if {[lindex $segs $i] == 1} {
      set c $color
    }
    set r [lindex $coords $i]
    fill_rect $base $width [lindex $r 0] [lindex $r 1] [lindex $r 2] [lindex $r 3] $c
  }
}

proc load_dmem {base mem_file} {
  set fp [open $mem_file r]
  set index 0
  while {[gets $fp line] >= 0} {
    set value [string trim $line]
    if {$value eq ""} {
      continue
    }
    mwr -force [expr {$base + ($index * 4)}] 0x$value
    incr index
  }
  close $fp
  return $index
}

proc run_one_digit {digit dmem_dir dmem_base lcd_base reg_control reg_status reg_pred reg_exp reg_hb reg_pc reg_data_addr reg_read_data reg_cycle_count} {
  set mem_file [file join $dmem_dir "lenet_digit${digit}_dmem.mem"]
  if {![file exists $mem_file]} {
    puts "EXTBRAM_DIGIT_${digit}_ERROR=DMEM_NOT_FOUND"
    return 0
  }

  mwr -force $reg_control 0x00000002
  after 10
  mwr -force $reg_control 0x00000000
  after 10

  puts "EXTBRAM_DIGIT_${digit}_DMEM_LOAD_BEGIN=1"
  set words [load_dmem $dmem_base $mem_file]
  puts "EXTBRAM_DIGIT_${digit}_DMEM_WORDS_WRITTEN=$words"

  mwr -force $reg_control 0x00000001

  set status 0
  for {set i 0} {$i < 400} {incr i} {
    after 50
    set status [read_word $reg_status]
    if {($status & 0x1) != 0} {
      break
    }
  }

  set pred [read_word $reg_pred]
  set expected [read_word $reg_exp]
  set cycle_count [read_word $reg_cycle_count]
  set latency_us [expr {$cycle_count / 100.0}]
  set done_ok [expr {($status & 0x1) != 0}]
  set pred_ok [expr {$pred == $digit}]
  set pass [expr {$done_ok && $pred_ok}]

  fill_rect $lcd_base 480 0 0 480 272 0x00000000
  fill_rect $lcd_base 480 0 0 480 16 0x0000FFFF
  fill_rect $lcd_base 480 0 256 480 16 0x0000FFFF
  fill_rect $lcd_base 480 0 0 16 272 0x0000FFFF
  fill_rect $lcd_base 480 464 0 16 272 0x0000FFFF

  set digit_color 0x000007E0
  set status_color 0x000007E0
  if {!$pass} {
    set digit_color 0x0000F800
    set status_color 0x0000F800
  }

  draw_digit7seg $lcd_base 480 192 36 1 $pred $digit_color 0x00001082
  fill_rect $lcd_base 480 48 214 384 28 $status_color

  puts "EXTBRAM_DIGIT_${digit}_STATUS_RAW=[mrd -force $reg_status]"
  puts "EXTBRAM_DIGIT_${digit}_HEARTBEAT_RAW=[mrd -force $reg_hb]"
  puts "EXTBRAM_DIGIT_${digit}_PC_RAW=[mrd -force $reg_pc]"
  puts "EXTBRAM_DIGIT_${digit}_DATA_ADDR_RAW=[mrd -force $reg_data_addr]"
  puts "EXTBRAM_DIGIT_${digit}_READ_DATA_RAW=[mrd -force $reg_read_data]"
  puts "EXTBRAM_DIGIT_${digit}_CYCLE_COUNT=$cycle_count"
  puts "EXTBRAM_DIGIT_${digit}_LATENCY_US_AT_100MHZ=$latency_us"
  puts "EXTBRAM_DIGIT_${digit}_PRED=$pred"
  puts "EXTBRAM_DIGIT_${digit}_EXPECTED=$expected"
  puts "EXTBRAM_DIGIT_${digit}_DONE_OK=$done_ok"
  puts "EXTBRAM_DIGIT_${digit}_PRED_OK=$pred_ok"
  puts "EXTBRAM_DIGIT_${digit}_PASS=$pass"
  puts "EXTBRAM_DIGIT_${digit}_SUMMARY=digit=$digit pred=$pred expected=$expected cycles=$cycle_count latency_us=$latency_us pass=$pass"

  return $pass
}

puts "EXTBRAM_0_TO_9_REPEAT_COUNT=$repeat_count"
puts "EXTBRAM_DIGIT_START=$digit_start"
puts "EXTBRAM_DIGIT_END=$digit_end"
puts "EXTBRAM_DMEM_DIR=$dmem_dir"
puts "EXTBRAM_DMEM_BASEADDR=0x43C40000"

set total_runs 0
set total_pass 0
for {set rep 0} {$rep < $repeat_count} {incr rep} {
  puts "EXTBRAM_REPEAT_BEGIN=[expr {$rep + 1}]"
  for {set digit $digit_start} {$digit <= $digit_end} {incr digit} {
    set pass [run_one_digit $digit $dmem_dir $dmem_base $lcd_base $reg_control $reg_status $reg_pred $reg_exp $reg_hb $reg_pc $reg_data_addr $reg_read_data $reg_cycle_count]
    incr total_runs
    if {$pass} {
      incr total_pass
    }
    after 300
  }
  puts "EXTBRAM_REPEAT_END=[expr {$rep + 1}]"
}

set all_pass [expr {$total_runs == $total_pass}]
puts "EXTBRAM_0_TO_9_TOTAL_RUNS=$total_runs"
puts "EXTBRAM_0_TO_9_TOTAL_PASS=$total_pass"
puts "EXTBRAM_0_TO_9_ALL_PASS=$all_pass"

disconnect
