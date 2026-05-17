
create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list ps_system/design_1_i/clk_wiz_0/inst/clk_200]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 32 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {inst[0]} {inst[1]} {inst[2]} {inst[3]} {inst[4]} {inst[5]} {inst[6]} {inst[7]} {inst[8]} {inst[9]} {inst[10]} {inst[11]} {inst[12]} {inst[13]} {inst[14]} {inst[15]} {inst[16]} {inst[17]} {inst[18]} {inst[19]} {inst[20]} {inst[21]} {inst[22]} {inst[23]} {inst[24]} {inst[25]} {inst[26]} {inst[27]} {inst[28]} {inst[29]} {inst[30]} {inst[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 32 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {write_data[0]} {write_data[1]} {write_data[2]} {write_data[3]} {write_data[4]} {write_data[5]} {write_data[6]} {write_data[7]} {write_data[8]} {write_data[9]} {write_data[10]} {write_data[11]} {write_data[12]} {write_data[13]} {write_data[14]} {write_data[15]} {write_data[16]} {write_data[17]} {write_data[18]} {write_data[19]} {write_data[20]} {write_data[21]} {write_data[22]} {write_data[23]} {write_data[24]} {write_data[25]} {write_data[26]} {write_data[27]} {write_data[28]} {write_data[29]} {write_data[30]} {write_data[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 32 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {read_data[0]} {read_data[1]} {read_data[2]} {read_data[3]} {read_data[4]} {read_data[5]} {read_data[6]} {read_data[7]} {read_data[8]} {read_data[9]} {read_data[10]} {read_data[11]} {read_data[12]} {read_data[13]} {read_data[14]} {read_data[15]} {read_data[16]} {read_data[17]} {read_data[18]} {read_data[19]} {read_data[20]} {read_data[21]} {read_data[22]} {read_data[23]} {read_data[24]} {read_data[25]} {read_data[26]} {read_data[27]} {read_data[28]} {read_data[29]} {read_data[30]} {read_data[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 32 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {data_addr[0]} {data_addr[1]} {data_addr[2]} {data_addr[3]} {data_addr[4]} {data_addr[5]} {data_addr[6]} {data_addr[7]} {data_addr[8]} {data_addr[9]} {data_addr[10]} {data_addr[11]} {data_addr[12]} {data_addr[13]} {data_addr[14]} {data_addr[15]} {data_addr[16]} {data_addr[17]} {data_addr[18]} {data_addr[19]} {data_addr[20]} {data_addr[21]} {data_addr[22]} {data_addr[23]} {data_addr[24]} {data_addr[25]} {data_addr[26]} {data_addr[27]} {data_addr[28]} {data_addr[29]} {data_addr[30]} {data_addr[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 4 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {ByteEnable[0]} {ByteEnable[1]} {ByteEnable[2]} {ByteEnable[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 32 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {fetch_addr[0]} {fetch_addr[1]} {fetch_addr[2]} {fetch_addr[3]} {fetch_addr[4]} {fetch_addr[5]} {fetch_addr[6]} {fetch_addr[7]} {fetch_addr[8]} {fetch_addr[9]} {fetch_addr[10]} {fetch_addr[11]} {fetch_addr[12]} {fetch_addr[13]} {fetch_addr[14]} {fetch_addr[15]} {fetch_addr[16]} {fetch_addr[17]} {fetch_addr[18]} {fetch_addr[19]} {fetch_addr[20]} {fetch_addr[21]} {fetch_addr[22]} {fetch_addr[23]} {fetch_addr[24]} {fetch_addr[25]} {fetch_addr[26]} {fetch_addr[27]} {fetch_addr[28]} {fetch_addr[29]} {fetch_addr[30]} {fetch_addr[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list data_we]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list is_halted]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
