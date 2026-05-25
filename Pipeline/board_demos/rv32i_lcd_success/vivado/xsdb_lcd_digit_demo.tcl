connect -url tcp:127.0.0.1:3121
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

set lcd_base 0x43C80000
set lcd_width 480
set lcd_height 272

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
  set xd [expr {$xa}]
  set yd [expr {$y + (2 * $v) + (2 * $t) + (3 * $gap)}]
  set xg [expr {$xa}]
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

mwr -force $reg_control 0x00000002
mwr -force $reg_control 0x00000001

set status 0
for {set i 0} {$i < 200} {incr i} {
  after 100
  set status [read_word $reg_status]
  if {($status & 0x1) != 0} {
    break
  }
}

set pred [read_word $reg_pred]
set expected [read_word $reg_exp]
set pass [expr {(($status & 0x3) == 0x3) && ($pred == $expected)}]

fill_rect $lcd_base $lcd_width 0 0 $lcd_width $lcd_height 0x00000000
fill_rect $lcd_base $lcd_width 0 0 $lcd_width 16 0x0000FFFF
fill_rect $lcd_base $lcd_width 0 256 $lcd_width 16 0x0000FFFF
fill_rect $lcd_base $lcd_width 0 0 16 $lcd_height 0x0000FFFF
fill_rect $lcd_base $lcd_width 464 0 16 $lcd_height 0x0000FFFF

set digit_color 0x000007E0
set status_color 0x000007E0
if {!$pass} {
  set digit_color 0x0000F800
  set status_color 0x0000F800
}

draw_digit7seg $lcd_base $lcd_width 192 36 1 $pred $digit_color 0x00001082
fill_rect $lcd_base $lcd_width 48 214 384 28 $status_color

puts "LCD_DIGIT_DEMO_STATUS_RAW=[mrd -force $reg_status]"
puts "LCD_DIGIT_DEMO_PRED=$pred"
puts "LCD_DIGIT_DEMO_EXPECTED=$expected"
puts "LCD_DIGIT_DEMO_PASS=$pass"

disconnect
