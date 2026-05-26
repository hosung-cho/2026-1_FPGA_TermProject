## Copy this file to board.xdc and fill in the real package pins for your board.
## Target FPGA part: xc7z020clg484-1

## Clock input connected to RV32I_Board_Top.CLOCK_50.
## Use the actual oscillator period:
## - 100 MHz clock: 10.000 ns
## -  50 MHz clock: 20.000 ns
create_clock -period 10.000 -name sys_clk [get_ports CLOCK_50]
# set_property PACKAGE_PIN <CLK_PIN> [get_ports CLOCK_50]
# set_property IOSTANDARD LVCMOS33 [get_ports CLOCK_50]

## Reset input. RV32I_Board_Top.reset follows the existing project convention:
## reset=0 holds the CPU in reset, reset=1 runs the CPU.
# set_property PACKAGE_PIN <RESET_PIN> [get_ports reset]
# set_property IOSTANDARD LVCMOS33 [get_ports reset]

## LED[0]   = inference done
## LED[4:1] = predicted digit
## LED[5]   = pass for bundled digit7 DMEM image
## LED[6]   = fail for bundled digit7 DMEM image
## LED[7]   = heartbeat
# set_property PACKAGE_PIN <LED0_PIN> [get_ports {LED[0]}]
# set_property PACKAGE_PIN <LED1_PIN> [get_ports {LED[1]}]
# set_property PACKAGE_PIN <LED2_PIN> [get_ports {LED[2]}]
# set_property PACKAGE_PIN <LED3_PIN> [get_ports {LED[3]}]
# set_property PACKAGE_PIN <LED4_PIN> [get_ports {LED[4]}]
# set_property PACKAGE_PIN <LED5_PIN> [get_ports {LED[5]}]
# set_property PACKAGE_PIN <LED6_PIN> [get_ports {LED[6]}]
# set_property PACKAGE_PIN <LED7_PIN> [get_ports {LED[7]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {LED[*]}]
