set moduleName CNN_ALU_Top
set isTopModule 1
set isTaskLevelControl 1
set isCombinational 0
set isDatapathOnly 0
set isFreeRunPipelineModule 0
set isPipelined 0
set pipeline_type none
set FunctionProtocol ap_ctrl_hs
set isOneStateSeq 0
set ProfileFlag 0
set StallSigGenFlag 0
set isEnableWaveformDebug 1
set C_modelName {CNN_ALU_Top}
set C_modelType { void 0 }
set C_modelArgList {
	{ rs1_data_V int 32 regular  }
	{ cnn_op_V int 4 regular  }
	{ rd_data_V int 32 regular {pointer 1}  }
}
set C_modelArgMapList {[ 
	{ "Name" : "rs1_data_V", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY", "bitSlice":[{"low":0,"up":31,"cElement": [{"cName": "rs1_data.V","cData": "uint32","bit_use": { "low": 0,"up": 31},"cArray": [{"low" : 0,"up" : 0,"step" : 0}]}]}]} , 
 	{ "Name" : "cnn_op_V", "interface" : "wire", "bitwidth" : 4, "direction" : "READONLY", "bitSlice":[{"low":0,"up":3,"cElement": [{"cName": "cnn_op.V","cData": "uint4","bit_use": { "low": 0,"up": 3},"cArray": [{"low" : 0,"up" : 0,"step" : 0}]}]}]} , 
 	{ "Name" : "rd_data_V", "interface" : "wire", "bitwidth" : 32, "direction" : "WRITEONLY", "bitSlice":[{"low":0,"up":31,"cElement": [{"cName": "rd_data.V","cData": "uint32","bit_use": { "low": 0,"up": 31},"cArray": [{"low" : 0,"up" : 0,"step" : 1}]}]}]} ]}
# RTL Port declarations: 
set portNum 9
set portList { 
	{ ap_clk sc_in sc_logic 1 clock -1 } 
	{ ap_rst sc_in sc_logic 1 reset -1 active_high_sync } 
	{ ap_start sc_in sc_logic 1 start -1 } 
	{ ap_done sc_out sc_logic 1 predone -1 } 
	{ ap_idle sc_out sc_logic 1 done -1 } 
	{ ap_ready sc_out sc_logic 1 ready -1 } 
	{ rs1_data_V sc_in sc_lv 32 signal 0 } 
	{ cnn_op_V sc_in sc_lv 4 signal 1 } 
	{ rd_data_V sc_out sc_lv 32 signal 2 } 
}
set NewPortList {[ 
	{ "name": "ap_clk", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "clock", "bundle":{"name": "ap_clk", "role": "default" }} , 
 	{ "name": "ap_rst", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "reset", "bundle":{"name": "ap_rst", "role": "default" }} , 
 	{ "name": "ap_start", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "start", "bundle":{"name": "ap_start", "role": "default" }} , 
 	{ "name": "ap_done", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "predone", "bundle":{"name": "ap_done", "role": "default" }} , 
 	{ "name": "ap_idle", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "done", "bundle":{"name": "ap_idle", "role": "default" }} , 
 	{ "name": "ap_ready", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "ready", "bundle":{"name": "ap_ready", "role": "default" }} , 
 	{ "name": "rs1_data_V", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "rs1_data_V", "role": "default" }} , 
 	{ "name": "cnn_op_V", "direction": "in", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "cnn_op_V", "role": "default" }} , 
 	{ "name": "rd_data_V", "direction": "out", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "rd_data_V", "role": "default" }}  ]}

set RtlHierarchyInfo {[
	{"ID" : "0", "Level" : "0", "Path" : "`AUTOTB_DUT_INST", "Parent" : "", "Child" : ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22"],
		"CDFG" : "CNN_ALU_Top",
		"Protocol" : "ap_ctrl_hs",
		"ControlExist" : "1", "ap_start" : "1", "ap_ready" : "1", "ap_done" : "1", "ap_continue" : "0", "ap_idle" : "1",
		"Pipeline" : "None", "UnalignedPipeline" : "0", "RewindPipeline" : "0", "ProcessNetwork" : "0",
		"II" : "0",
		"VariableLatency" : "1", "ExactLatency" : "-1", "EstimateLatencyMin" : "1", "EstimateLatencyMax" : "11",
		"Combinational" : "0",
		"Datapath" : "0",
		"ClockEnable" : "0",
		"HasSubDataflow" : "0",
		"InDataflowNetwork" : "0",
		"HasNonBlockingOperation" : "0",
		"Port" : [
			{"Name" : "rs1_data_V", "Type" : "None", "Direction" : "I"},
			{"Name" : "cnn_op_V", "Type" : "None", "Direction" : "I"},
			{"Name" : "rd_data_V", "Type" : "None", "Direction" : "O"},
			{"Name" : "weight_buf_V_0", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_1", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_2", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_3", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_4", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_5", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_6", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_7", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_8", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_9", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_10", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_11", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_12", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_13", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_14", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_15", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_16", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_17", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_18", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_19", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_20", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_21", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_22", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_23", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_24", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_0", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_1", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_2", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_3", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_4", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_5", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_6", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_7", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_8", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_9", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_10", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_11", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_12", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_13", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_14", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_15", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_16", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_17", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_18", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_19", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_20", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_21", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_22", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_23", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_24", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "acc_reg_V", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "w_ptr", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "a_ptr", "Type" : "OVld", "Direction" : "IO"}]},
	{"ID" : "1", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U1", "Parent" : "0"},
	{"ID" : "2", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U2", "Parent" : "0"},
	{"ID" : "3", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U3", "Parent" : "0"},
	{"ID" : "4", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U4", "Parent" : "0"},
	{"ID" : "5", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U5", "Parent" : "0"},
	{"ID" : "6", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U6", "Parent" : "0"},
	{"ID" : "7", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U7", "Parent" : "0"},
	{"ID" : "8", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U8", "Parent" : "0"},
	{"ID" : "9", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U9", "Parent" : "0"},
	{"ID" : "10", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U10", "Parent" : "0"},
	{"ID" : "11", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U11", "Parent" : "0"},
	{"ID" : "12", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U12", "Parent" : "0"},
	{"ID" : "13", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U13", "Parent" : "0"},
	{"ID" : "14", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U14", "Parent" : "0"},
	{"ID" : "15", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U15", "Parent" : "0"},
	{"ID" : "16", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U16", "Parent" : "0"},
	{"ID" : "17", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U17", "Parent" : "0"},
	{"ID" : "18", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U18", "Parent" : "0"},
	{"ID" : "19", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U19", "Parent" : "0"},
	{"ID" : "20", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U20", "Parent" : "0"},
	{"ID" : "21", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U21", "Parent" : "0"},
	{"ID" : "22", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U22", "Parent" : "0"}]}


set ArgLastReadFirstWriteLatency {
	CNN_ALU_Top {
		rs1_data_V {Type I LastRead 0 FirstWrite -1}
		cnn_op_V {Type I LastRead 0 FirstWrite -1}
		rd_data_V {Type O LastRead -1 FirstWrite 0}
		weight_buf_V_0 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_1 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_2 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_3 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_4 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_5 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_6 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_7 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_8 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_9 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_10 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_11 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_12 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_13 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_14 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_15 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_16 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_17 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_18 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_19 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_20 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_21 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_22 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_23 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_24 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_0 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_1 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_2 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_3 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_4 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_5 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_6 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_7 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_8 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_9 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_10 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_11 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_12 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_13 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_14 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_15 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_16 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_17 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_18 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_19 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_20 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_21 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_22 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_23 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_24 {Type IO LastRead -1 FirstWrite -1}
		acc_reg_V {Type IO LastRead -1 FirstWrite -1}
		w_ptr {Type IO LastRead -1 FirstWrite -1}
		a_ptr {Type IO LastRead -1 FirstWrite -1}}}

set hasDtUnsupportedChannel 0

set PerformanceInfo {[
	{"Name" : "Latency", "Min" : "1", "Max" : "11"}
	, {"Name" : "Interval", "Min" : "2", "Max" : "12"}
]}

set PipelineEnableSignalInfo {[
	{"Pipeline" : "0", "EnableSignal" : "ap_enable_pp0"}
	{"Pipeline" : "1", "EnableSignal" : "ap_enable_pp1"}
]}

set Spec2ImplPortList { 
	rs1_data_V { ap_none {  { rs1_data_V in_data 0 32 } } }
	cnn_op_V { ap_none {  { cnn_op_V in_data 0 4 } } }
	rd_data_V { ap_none {  { rd_data_V out_data 1 32 } } }
}

set busDeadlockParameterList { 
}

# RTL port scheduling information:
set fifoSchedulingInfoList { 
}

# RTL bus port read request latency information:
set busReadReqLatencyList { 
}

# RTL bus port write response latency information:
set busWriteResLatencyList { 
}

# RTL array port load latency information:
set memoryLoadLatencyList { 
}
