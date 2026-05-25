connect -url tcp:127.0.0.1:3121
targets -set -filter {name =~ "ARM Cortex-A9 MPCore #0"}
memmap -addr 0x43C00000 -size 0x10000 -flags 3
memmap -addr 0x43C40000 -size 0x20000 -flags 3

source C:/rv32i_lcd_extbram_bd_impl/rv32i_lenet_ps_lcd_extbram_bd_impl.srcs/sources_1/bd/design_1/ip/design_1_ps7_0_0/ps7_init.tcl
ps7_init
ps7_post_config

mwr -force 0x43C00000 0x00000000

mwr -force 0x43C40000 0x11223344
mwr -force 0x43C40004 0x55667788

puts "EXTBRAM_PROBE_0=[mrd -force 0x43C40000]"
puts "EXTBRAM_PROBE_4=[mrd -force 0x43C40004]"
puts "EXTBRAM_CTRL=[mrd -force 0x43C00000]"

disconnect
