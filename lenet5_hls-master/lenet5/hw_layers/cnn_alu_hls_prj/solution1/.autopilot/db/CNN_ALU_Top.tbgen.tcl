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
	{ cnn_op_V int 3 regular  }
	{ rd_data_V int 32 regular {pointer 1}  }
}
set C_modelArgMapList {[ 
	{ "Name" : "rs1_data_V", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY", "bitSlice":[{"low":0,"up":31,"cElement": [{"cName": "rs1_data.V","cData": "uint32","bit_use": { "low": 0,"up": 31},"cArray": [{"low" : 0,"up" : 0,"step" : 0}]}]}]} , 
 	{ "Name" : "cnn_op_V", "interface" : "wire", "bitwidth" : 3, "direction" : "READONLY", "bitSlice":[{"low":0,"up":2,"cElement": [{"cName": "cnn_op.V","cData": "uint3","bit_use": { "low": 0,"up": 2},"cArray": [{"low" : 0,"up" : 0,"step" : 0}]}]}]} , 
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
	{ cnn_op_V sc_in sc_lv 3 signal 1 } 
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
 	{ "name": "cnn_op_V", "direction": "in", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "cnn_op_V", "role": "default" }} , 
 	{ "name": "rd_data_V", "direction": "out", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "rd_data_V", "role": "default" }}  ]}

set RtlHierarchyInfo {[
	{"ID" : "0", "Level" : "0", "Path" : "`AUTOTB_DUT_INST", "Parent" : "", "Child" : ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47", "48", "49", "50", "51", "52", "53", "54", "55", "56", "57", "58", "59", "60", "61", "62", "63", "64", "65", "66", "67", "68", "69", "70", "71", "72", "73", "74", "75", "76", "77", "78", "79", "80", "81", "82", "83", "84", "85", "86", "87", "88", "89", "90", "91", "92", "93", "94", "95", "96", "97", "98", "99", "100", "101", "102", "103", "104", "105", "106", "107", "108", "109", "110", "111", "112", "113", "114", "115", "116", "117", "118", "119", "120", "121", "122", "123", "124", "125", "126", "127", "128", "129", "130", "131", "132", "133", "134", "135", "136", "137", "138", "139", "140", "141", "142", "143", "144", "145", "146", "147", "148", "149", "150", "151", "152", "153", "154", "155", "156", "157", "158", "159", "160", "161", "162", "163", "164", "165", "166", "167", "168", "169", "170", "171", "172", "173", "174", "175", "176", "177", "178", "179", "180", "181", "182", "183", "184", "185", "186", "187", "188", "189", "190", "191", "192", "193", "194", "195", "196", "197", "198", "199", "200", "201", "202", "203", "204", "205", "206", "207", "208", "209", "210", "211", "212", "213", "214", "215", "216", "217", "218", "219", "220", "221", "222", "223", "224", "225", "226", "227", "228", "229", "230", "231", "232", "233", "234", "235", "236", "237", "238", "239", "240", "241", "242", "243", "244", "245", "246", "247", "248", "249", "250", "251", "252", "253", "254", "255", "256", "257", "258", "259", "260", "261", "262", "263", "264", "265", "266", "267", "268", "269", "270", "271", "272", "273", "274", "275", "276", "277", "278", "279", "280", "281", "282", "283", "284", "285", "286", "287", "288", "289", "290", "291", "292", "293", "294", "295", "296", "297", "298", "299", "300", "301", "302", "303", "304", "305", "306", "307", "308", "309", "310", "311", "312", "313", "314", "315", "316", "317", "318", "319", "320", "321", "322", "323", "324", "325", "326", "327", "328", "329", "330", "331", "332", "333", "334", "335", "336", "337", "338", "339", "340", "341", "342", "343", "344", "345", "346", "347", "348", "349", "350", "351", "352", "353", "354", "355", "356", "357", "358", "359", "360"],
		"CDFG" : "CNN_ALU_Top",
		"Protocol" : "ap_ctrl_hs",
		"ControlExist" : "1", "ap_start" : "1", "ap_ready" : "1", "ap_done" : "1", "ap_continue" : "0", "ap_idle" : "1",
		"Pipeline" : "None", "UnalignedPipeline" : "0", "RewindPipeline" : "0", "ProcessNetwork" : "0",
		"II" : "0",
		"VariableLatency" : "1", "ExactLatency" : "-1", "EstimateLatencyMin" : "1", "EstimateLatencyMax" : "9",
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
			{"Name" : "act_buf_V_0", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_1", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_2", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_3", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_3", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_7", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_11", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_15", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_19", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_23", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_2", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_6", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_10", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_14", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_18", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_22", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_1", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_5", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_9", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_13", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_17", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_21", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_0", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_4", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_8", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_12", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_16", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_20", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_24", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_7", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_11", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_15", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_19", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_23", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_6", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_10", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_14", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_18", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_22", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_5", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_9", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_13", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_17", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_21", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_4", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_8", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_12", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_16", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_20", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_24", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "w_ptr", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "a_ptr", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "acc_reg_V", "Type" : "OVld", "Direction" : "IO"}]},
	{"ID" : "1", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U1", "Parent" : "0"},
	{"ID" : "2", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U2", "Parent" : "0"},
	{"ID" : "3", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U3", "Parent" : "0"},
	{"ID" : "4", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U4", "Parent" : "0"},
	{"ID" : "5", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U5", "Parent" : "0"},
	{"ID" : "6", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U6", "Parent" : "0"},
	{"ID" : "7", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U7", "Parent" : "0"},
	{"ID" : "8", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U8", "Parent" : "0"},
	{"ID" : "9", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U9", "Parent" : "0"},
	{"ID" : "10", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U10", "Parent" : "0"},
	{"ID" : "11", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U11", "Parent" : "0"},
	{"ID" : "12", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U12", "Parent" : "0"},
	{"ID" : "13", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U13", "Parent" : "0"},
	{"ID" : "14", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U14", "Parent" : "0"},
	{"ID" : "15", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U15", "Parent" : "0"},
	{"ID" : "16", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U16", "Parent" : "0"},
	{"ID" : "17", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U17", "Parent" : "0"},
	{"ID" : "18", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U18", "Parent" : "0"},
	{"ID" : "19", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U19", "Parent" : "0"},
	{"ID" : "20", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U20", "Parent" : "0"},
	{"ID" : "21", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U21", "Parent" : "0"},
	{"ID" : "22", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U22", "Parent" : "0"},
	{"ID" : "23", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U23", "Parent" : "0"},
	{"ID" : "24", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U24", "Parent" : "0"},
	{"ID" : "25", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U25", "Parent" : "0"},
	{"ID" : "26", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U26", "Parent" : "0"},
	{"ID" : "27", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U27", "Parent" : "0"},
	{"ID" : "28", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U28", "Parent" : "0"},
	{"ID" : "29", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U29", "Parent" : "0"},
	{"ID" : "30", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U30", "Parent" : "0"},
	{"ID" : "31", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U31", "Parent" : "0"},
	{"ID" : "32", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U32", "Parent" : "0"},
	{"ID" : "33", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U33", "Parent" : "0"},
	{"ID" : "34", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U34", "Parent" : "0"},
	{"ID" : "35", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U35", "Parent" : "0"},
	{"ID" : "36", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U36", "Parent" : "0"},
	{"ID" : "37", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U37", "Parent" : "0"},
	{"ID" : "38", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U38", "Parent" : "0"},
	{"ID" : "39", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U39", "Parent" : "0"},
	{"ID" : "40", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U40", "Parent" : "0"},
	{"ID" : "41", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U41", "Parent" : "0"},
	{"ID" : "42", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U42", "Parent" : "0"},
	{"ID" : "43", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U43", "Parent" : "0"},
	{"ID" : "44", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U44", "Parent" : "0"},
	{"ID" : "45", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U45", "Parent" : "0"},
	{"ID" : "46", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U46", "Parent" : "0"},
	{"ID" : "47", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U47", "Parent" : "0"},
	{"ID" : "48", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U48", "Parent" : "0"},
	{"ID" : "49", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U49", "Parent" : "0"},
	{"ID" : "50", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U50", "Parent" : "0"},
	{"ID" : "51", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U51", "Parent" : "0"},
	{"ID" : "52", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U52", "Parent" : "0"},
	{"ID" : "53", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U53", "Parent" : "0"},
	{"ID" : "54", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U54", "Parent" : "0"},
	{"ID" : "55", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U55", "Parent" : "0"},
	{"ID" : "56", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U56", "Parent" : "0"},
	{"ID" : "57", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U57", "Parent" : "0"},
	{"ID" : "58", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U58", "Parent" : "0"},
	{"ID" : "59", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U59", "Parent" : "0"},
	{"ID" : "60", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U60", "Parent" : "0"},
	{"ID" : "61", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U61", "Parent" : "0"},
	{"ID" : "62", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U62", "Parent" : "0"},
	{"ID" : "63", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U63", "Parent" : "0"},
	{"ID" : "64", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U64", "Parent" : "0"},
	{"ID" : "65", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U65", "Parent" : "0"},
	{"ID" : "66", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U66", "Parent" : "0"},
	{"ID" : "67", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U67", "Parent" : "0"},
	{"ID" : "68", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U68", "Parent" : "0"},
	{"ID" : "69", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U69", "Parent" : "0"},
	{"ID" : "70", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U70", "Parent" : "0"},
	{"ID" : "71", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U71", "Parent" : "0"},
	{"ID" : "72", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U72", "Parent" : "0"},
	{"ID" : "73", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U73", "Parent" : "0"},
	{"ID" : "74", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U74", "Parent" : "0"},
	{"ID" : "75", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U75", "Parent" : "0"},
	{"ID" : "76", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U76", "Parent" : "0"},
	{"ID" : "77", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U77", "Parent" : "0"},
	{"ID" : "78", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U78", "Parent" : "0"},
	{"ID" : "79", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U79", "Parent" : "0"},
	{"ID" : "80", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U80", "Parent" : "0"},
	{"ID" : "81", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U81", "Parent" : "0"},
	{"ID" : "82", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U82", "Parent" : "0"},
	{"ID" : "83", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U83", "Parent" : "0"},
	{"ID" : "84", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U84", "Parent" : "0"},
	{"ID" : "85", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U85", "Parent" : "0"},
	{"ID" : "86", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U86", "Parent" : "0"},
	{"ID" : "87", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U87", "Parent" : "0"},
	{"ID" : "88", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U88", "Parent" : "0"},
	{"ID" : "89", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U89", "Parent" : "0"},
	{"ID" : "90", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U90", "Parent" : "0"},
	{"ID" : "91", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U91", "Parent" : "0"},
	{"ID" : "92", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U92", "Parent" : "0"},
	{"ID" : "93", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U93", "Parent" : "0"},
	{"ID" : "94", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U94", "Parent" : "0"},
	{"ID" : "95", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U95", "Parent" : "0"},
	{"ID" : "96", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U96", "Parent" : "0"},
	{"ID" : "97", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U97", "Parent" : "0"},
	{"ID" : "98", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U98", "Parent" : "0"},
	{"ID" : "99", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U99", "Parent" : "0"},
	{"ID" : "100", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U100", "Parent" : "0"},
	{"ID" : "101", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U101", "Parent" : "0"},
	{"ID" : "102", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U102", "Parent" : "0"},
	{"ID" : "103", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U103", "Parent" : "0"},
	{"ID" : "104", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U104", "Parent" : "0"},
	{"ID" : "105", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U105", "Parent" : "0"},
	{"ID" : "106", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U106", "Parent" : "0"},
	{"ID" : "107", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U107", "Parent" : "0"},
	{"ID" : "108", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U108", "Parent" : "0"},
	{"ID" : "109", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U109", "Parent" : "0"},
	{"ID" : "110", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U110", "Parent" : "0"},
	{"ID" : "111", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U111", "Parent" : "0"},
	{"ID" : "112", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U112", "Parent" : "0"},
	{"ID" : "113", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U113", "Parent" : "0"},
	{"ID" : "114", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U114", "Parent" : "0"},
	{"ID" : "115", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U115", "Parent" : "0"},
	{"ID" : "116", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U116", "Parent" : "0"},
	{"ID" : "117", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U117", "Parent" : "0"},
	{"ID" : "118", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U118", "Parent" : "0"},
	{"ID" : "119", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U119", "Parent" : "0"},
	{"ID" : "120", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U120", "Parent" : "0"},
	{"ID" : "121", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U121", "Parent" : "0"},
	{"ID" : "122", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U122", "Parent" : "0"},
	{"ID" : "123", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U123", "Parent" : "0"},
	{"ID" : "124", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U124", "Parent" : "0"},
	{"ID" : "125", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U125", "Parent" : "0"},
	{"ID" : "126", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U126", "Parent" : "0"},
	{"ID" : "127", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U127", "Parent" : "0"},
	{"ID" : "128", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U128", "Parent" : "0"},
	{"ID" : "129", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U129", "Parent" : "0"},
	{"ID" : "130", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U130", "Parent" : "0"},
	{"ID" : "131", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U131", "Parent" : "0"},
	{"ID" : "132", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U132", "Parent" : "0"},
	{"ID" : "133", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U133", "Parent" : "0"},
	{"ID" : "134", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U134", "Parent" : "0"},
	{"ID" : "135", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U135", "Parent" : "0"},
	{"ID" : "136", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U136", "Parent" : "0"},
	{"ID" : "137", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U137", "Parent" : "0"},
	{"ID" : "138", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U138", "Parent" : "0"},
	{"ID" : "139", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U139", "Parent" : "0"},
	{"ID" : "140", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U140", "Parent" : "0"},
	{"ID" : "141", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U141", "Parent" : "0"},
	{"ID" : "142", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U142", "Parent" : "0"},
	{"ID" : "143", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U143", "Parent" : "0"},
	{"ID" : "144", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U144", "Parent" : "0"},
	{"ID" : "145", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U145", "Parent" : "0"},
	{"ID" : "146", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U146", "Parent" : "0"},
	{"ID" : "147", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U147", "Parent" : "0"},
	{"ID" : "148", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U148", "Parent" : "0"},
	{"ID" : "149", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U149", "Parent" : "0"},
	{"ID" : "150", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U150", "Parent" : "0"},
	{"ID" : "151", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U151", "Parent" : "0"},
	{"ID" : "152", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U152", "Parent" : "0"},
	{"ID" : "153", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U153", "Parent" : "0"},
	{"ID" : "154", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U154", "Parent" : "0"},
	{"ID" : "155", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U155", "Parent" : "0"},
	{"ID" : "156", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U156", "Parent" : "0"},
	{"ID" : "157", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U157", "Parent" : "0"},
	{"ID" : "158", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U158", "Parent" : "0"},
	{"ID" : "159", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U159", "Parent" : "0"},
	{"ID" : "160", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U160", "Parent" : "0"},
	{"ID" : "161", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U161", "Parent" : "0"},
	{"ID" : "162", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U162", "Parent" : "0"},
	{"ID" : "163", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U163", "Parent" : "0"},
	{"ID" : "164", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U164", "Parent" : "0"},
	{"ID" : "165", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U165", "Parent" : "0"},
	{"ID" : "166", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U166", "Parent" : "0"},
	{"ID" : "167", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U167", "Parent" : "0"},
	{"ID" : "168", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U168", "Parent" : "0"},
	{"ID" : "169", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U169", "Parent" : "0"},
	{"ID" : "170", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U170", "Parent" : "0"},
	{"ID" : "171", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U171", "Parent" : "0"},
	{"ID" : "172", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U172", "Parent" : "0"},
	{"ID" : "173", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U173", "Parent" : "0"},
	{"ID" : "174", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U174", "Parent" : "0"},
	{"ID" : "175", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U175", "Parent" : "0"},
	{"ID" : "176", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U176", "Parent" : "0"},
	{"ID" : "177", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U177", "Parent" : "0"},
	{"ID" : "178", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U178", "Parent" : "0"},
	{"ID" : "179", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U179", "Parent" : "0"},
	{"ID" : "180", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U180", "Parent" : "0"},
	{"ID" : "181", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U181", "Parent" : "0"},
	{"ID" : "182", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U182", "Parent" : "0"},
	{"ID" : "183", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U183", "Parent" : "0"},
	{"ID" : "184", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U184", "Parent" : "0"},
	{"ID" : "185", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U185", "Parent" : "0"},
	{"ID" : "186", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U186", "Parent" : "0"},
	{"ID" : "187", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U187", "Parent" : "0"},
	{"ID" : "188", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U188", "Parent" : "0"},
	{"ID" : "189", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U189", "Parent" : "0"},
	{"ID" : "190", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U190", "Parent" : "0"},
	{"ID" : "191", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U191", "Parent" : "0"},
	{"ID" : "192", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U192", "Parent" : "0"},
	{"ID" : "193", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U193", "Parent" : "0"},
	{"ID" : "194", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U194", "Parent" : "0"},
	{"ID" : "195", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U195", "Parent" : "0"},
	{"ID" : "196", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U196", "Parent" : "0"},
	{"ID" : "197", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U197", "Parent" : "0"},
	{"ID" : "198", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U198", "Parent" : "0"},
	{"ID" : "199", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U199", "Parent" : "0"},
	{"ID" : "200", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U200", "Parent" : "0"},
	{"ID" : "201", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U201", "Parent" : "0"},
	{"ID" : "202", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U202", "Parent" : "0"},
	{"ID" : "203", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U203", "Parent" : "0"},
	{"ID" : "204", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U204", "Parent" : "0"},
	{"ID" : "205", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U205", "Parent" : "0"},
	{"ID" : "206", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U206", "Parent" : "0"},
	{"ID" : "207", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U207", "Parent" : "0"},
	{"ID" : "208", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U208", "Parent" : "0"},
	{"ID" : "209", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U209", "Parent" : "0"},
	{"ID" : "210", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U210", "Parent" : "0"},
	{"ID" : "211", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U211", "Parent" : "0"},
	{"ID" : "212", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U212", "Parent" : "0"},
	{"ID" : "213", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U213", "Parent" : "0"},
	{"ID" : "214", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U214", "Parent" : "0"},
	{"ID" : "215", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U215", "Parent" : "0"},
	{"ID" : "216", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U216", "Parent" : "0"},
	{"ID" : "217", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U217", "Parent" : "0"},
	{"ID" : "218", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U218", "Parent" : "0"},
	{"ID" : "219", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U219", "Parent" : "0"},
	{"ID" : "220", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U220", "Parent" : "0"},
	{"ID" : "221", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U221", "Parent" : "0"},
	{"ID" : "222", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U222", "Parent" : "0"},
	{"ID" : "223", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U223", "Parent" : "0"},
	{"ID" : "224", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U224", "Parent" : "0"},
	{"ID" : "225", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U225", "Parent" : "0"},
	{"ID" : "226", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U226", "Parent" : "0"},
	{"ID" : "227", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U227", "Parent" : "0"},
	{"ID" : "228", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U228", "Parent" : "0"},
	{"ID" : "229", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U229", "Parent" : "0"},
	{"ID" : "230", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U230", "Parent" : "0"},
	{"ID" : "231", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U231", "Parent" : "0"},
	{"ID" : "232", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U232", "Parent" : "0"},
	{"ID" : "233", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U233", "Parent" : "0"},
	{"ID" : "234", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U234", "Parent" : "0"},
	{"ID" : "235", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U235", "Parent" : "0"},
	{"ID" : "236", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U236", "Parent" : "0"},
	{"ID" : "237", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U237", "Parent" : "0"},
	{"ID" : "238", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U238", "Parent" : "0"},
	{"ID" : "239", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U239", "Parent" : "0"},
	{"ID" : "240", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U240", "Parent" : "0"},
	{"ID" : "241", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U241", "Parent" : "0"},
	{"ID" : "242", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U242", "Parent" : "0"},
	{"ID" : "243", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U243", "Parent" : "0"},
	{"ID" : "244", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U244", "Parent" : "0"},
	{"ID" : "245", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U245", "Parent" : "0"},
	{"ID" : "246", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U246", "Parent" : "0"},
	{"ID" : "247", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U247", "Parent" : "0"},
	{"ID" : "248", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U248", "Parent" : "0"},
	{"ID" : "249", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U249", "Parent" : "0"},
	{"ID" : "250", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U250", "Parent" : "0"},
	{"ID" : "251", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U251", "Parent" : "0"},
	{"ID" : "252", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U252", "Parent" : "0"},
	{"ID" : "253", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U253", "Parent" : "0"},
	{"ID" : "254", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U254", "Parent" : "0"},
	{"ID" : "255", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U255", "Parent" : "0"},
	{"ID" : "256", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U256", "Parent" : "0"},
	{"ID" : "257", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U257", "Parent" : "0"},
	{"ID" : "258", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U258", "Parent" : "0"},
	{"ID" : "259", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U259", "Parent" : "0"},
	{"ID" : "260", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U260", "Parent" : "0"},
	{"ID" : "261", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U261", "Parent" : "0"},
	{"ID" : "262", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U262", "Parent" : "0"},
	{"ID" : "263", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U263", "Parent" : "0"},
	{"ID" : "264", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U264", "Parent" : "0"},
	{"ID" : "265", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U265", "Parent" : "0"},
	{"ID" : "266", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U266", "Parent" : "0"},
	{"ID" : "267", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U267", "Parent" : "0"},
	{"ID" : "268", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U268", "Parent" : "0"},
	{"ID" : "269", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U269", "Parent" : "0"},
	{"ID" : "270", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U270", "Parent" : "0"},
	{"ID" : "271", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U271", "Parent" : "0"},
	{"ID" : "272", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U272", "Parent" : "0"},
	{"ID" : "273", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U273", "Parent" : "0"},
	{"ID" : "274", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U274", "Parent" : "0"},
	{"ID" : "275", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U275", "Parent" : "0"},
	{"ID" : "276", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U276", "Parent" : "0"},
	{"ID" : "277", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U277", "Parent" : "0"},
	{"ID" : "278", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U278", "Parent" : "0"},
	{"ID" : "279", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U279", "Parent" : "0"},
	{"ID" : "280", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U280", "Parent" : "0"},
	{"ID" : "281", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U281", "Parent" : "0"},
	{"ID" : "282", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U282", "Parent" : "0"},
	{"ID" : "283", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U283", "Parent" : "0"},
	{"ID" : "284", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U284", "Parent" : "0"},
	{"ID" : "285", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U285", "Parent" : "0"},
	{"ID" : "286", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U286", "Parent" : "0"},
	{"ID" : "287", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U287", "Parent" : "0"},
	{"ID" : "288", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U288", "Parent" : "0"},
	{"ID" : "289", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U289", "Parent" : "0"},
	{"ID" : "290", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U290", "Parent" : "0"},
	{"ID" : "291", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U291", "Parent" : "0"},
	{"ID" : "292", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U292", "Parent" : "0"},
	{"ID" : "293", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U293", "Parent" : "0"},
	{"ID" : "294", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U294", "Parent" : "0"},
	{"ID" : "295", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U295", "Parent" : "0"},
	{"ID" : "296", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U296", "Parent" : "0"},
	{"ID" : "297", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U297", "Parent" : "0"},
	{"ID" : "298", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U298", "Parent" : "0"},
	{"ID" : "299", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U299", "Parent" : "0"},
	{"ID" : "300", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U300", "Parent" : "0"},
	{"ID" : "301", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U301", "Parent" : "0"},
	{"ID" : "302", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U302", "Parent" : "0"},
	{"ID" : "303", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U303", "Parent" : "0"},
	{"ID" : "304", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U304", "Parent" : "0"},
	{"ID" : "305", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U305", "Parent" : "0"},
	{"ID" : "306", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U306", "Parent" : "0"},
	{"ID" : "307", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U307", "Parent" : "0"},
	{"ID" : "308", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U308", "Parent" : "0"},
	{"ID" : "309", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U309", "Parent" : "0"},
	{"ID" : "310", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U310", "Parent" : "0"},
	{"ID" : "311", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U311", "Parent" : "0"},
	{"ID" : "312", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U312", "Parent" : "0"},
	{"ID" : "313", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U313", "Parent" : "0"},
	{"ID" : "314", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U314", "Parent" : "0"},
	{"ID" : "315", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U315", "Parent" : "0"},
	{"ID" : "316", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U316", "Parent" : "0"},
	{"ID" : "317", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U317", "Parent" : "0"},
	{"ID" : "318", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U318", "Parent" : "0"},
	{"ID" : "319", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U319", "Parent" : "0"},
	{"ID" : "320", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U320", "Parent" : "0"},
	{"ID" : "321", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U321", "Parent" : "0"},
	{"ID" : "322", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U322", "Parent" : "0"},
	{"ID" : "323", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U323", "Parent" : "0"},
	{"ID" : "324", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U324", "Parent" : "0"},
	{"ID" : "325", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U325", "Parent" : "0"},
	{"ID" : "326", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U326", "Parent" : "0"},
	{"ID" : "327", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U327", "Parent" : "0"},
	{"ID" : "328", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U328", "Parent" : "0"},
	{"ID" : "329", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U329", "Parent" : "0"},
	{"ID" : "330", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U330", "Parent" : "0"},
	{"ID" : "331", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U331", "Parent" : "0"},
	{"ID" : "332", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U332", "Parent" : "0"},
	{"ID" : "333", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U333", "Parent" : "0"},
	{"ID" : "334", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U334", "Parent" : "0"},
	{"ID" : "335", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U335", "Parent" : "0"},
	{"ID" : "336", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U336", "Parent" : "0"},
	{"ID" : "337", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U337", "Parent" : "0"},
	{"ID" : "338", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U338", "Parent" : "0"},
	{"ID" : "339", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U339", "Parent" : "0"},
	{"ID" : "340", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U340", "Parent" : "0"},
	{"ID" : "341", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U341", "Parent" : "0"},
	{"ID" : "342", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U342", "Parent" : "0"},
	{"ID" : "343", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U343", "Parent" : "0"},
	{"ID" : "344", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U344", "Parent" : "0"},
	{"ID" : "345", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U345", "Parent" : "0"},
	{"ID" : "346", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U346", "Parent" : "0"},
	{"ID" : "347", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U347", "Parent" : "0"},
	{"ID" : "348", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U348", "Parent" : "0"},
	{"ID" : "349", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U349", "Parent" : "0"},
	{"ID" : "350", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U350", "Parent" : "0"},
	{"ID" : "351", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U351", "Parent" : "0"},
	{"ID" : "352", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U352", "Parent" : "0"},
	{"ID" : "353", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U353", "Parent" : "0"},
	{"ID" : "354", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U354", "Parent" : "0"},
	{"ID" : "355", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U355", "Parent" : "0"},
	{"ID" : "356", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U356", "Parent" : "0"},
	{"ID" : "357", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U357", "Parent" : "0"},
	{"ID" : "358", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3cud_U358", "Parent" : "0"},
	{"ID" : "359", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U359", "Parent" : "0"},
	{"ID" : "360", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_meOg_U360", "Parent" : "0"}]}


set ArgLastReadFirstWriteLatency {
	CNN_ALU_Top {
		rs1_data_V {Type I LastRead 0 FirstWrite -1}
		cnn_op_V {Type I LastRead 0 FirstWrite -1}
		rd_data_V {Type O LastRead -1 FirstWrite 0}
		act_buf_V_0 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_1 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_2 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_3 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_3 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_7 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_11 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_15 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_19 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_23 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_2 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_6 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_10 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_14 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_18 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_22 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_1 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_5 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_9 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_13 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_17 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_21 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_0 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_4 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_8 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_12 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_16 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_20 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_24 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_7 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_11 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_15 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_19 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_23 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_6 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_10 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_14 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_18 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_22 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_5 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_9 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_13 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_17 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_21 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_4 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_8 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_12 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_16 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_20 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_24 {Type IO LastRead -1 FirstWrite -1}
		w_ptr {Type IO LastRead -1 FirstWrite -1}
		a_ptr {Type IO LastRead -1 FirstWrite -1}
		acc_reg_V {Type IO LastRead -1 FirstWrite -1}}}

set hasDtUnsupportedChannel 0

set PerformanceInfo {[
	{"Name" : "Latency", "Min" : "1", "Max" : "9"}
	, {"Name" : "Interval", "Min" : "2", "Max" : "10"}
]}

set PipelineEnableSignalInfo {[
	{"Pipeline" : "0", "EnableSignal" : "ap_enable_pp0"}
]}

set Spec2ImplPortList { 
	rs1_data_V { ap_none {  { rs1_data_V in_data 0 32 } } }
	cnn_op_V { ap_none {  { cnn_op_V in_data 0 3 } } }
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
	{ cnn_op_V int 3 regular  }
	{ rd_data_V int 32 regular {pointer 1}  }
}
set C_modelArgMapList {[ 
	{ "Name" : "rs1_data_V", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY", "bitSlice":[{"low":0,"up":31,"cElement": [{"cName": "rs1_data.V","cData": "uint32","bit_use": { "low": 0,"up": 31},"cArray": [{"low" : 0,"up" : 0,"step" : 0}]}]}]} , 
 	{ "Name" : "cnn_op_V", "interface" : "wire", "bitwidth" : 3, "direction" : "READONLY", "bitSlice":[{"low":0,"up":2,"cElement": [{"cName": "cnn_op.V","cData": "uint3","bit_use": { "low": 0,"up": 2},"cArray": [{"low" : 0,"up" : 0,"step" : 0}]}]}]} , 
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
	{ cnn_op_V sc_in sc_lv 3 signal 1 } 
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
 	{ "name": "cnn_op_V", "direction": "in", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "cnn_op_V", "role": "default" }} , 
 	{ "name": "rd_data_V", "direction": "out", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "rd_data_V", "role": "default" }}  ]}

set RtlHierarchyInfo {[
	{"ID" : "0", "Level" : "0", "Path" : "`AUTOTB_DUT_INST", "Parent" : "", "Child" : ["1", "2", "3", "4", "5", "6", "7", "8", "9"],
		"CDFG" : "CNN_ALU_Top",
		"Protocol" : "ap_ctrl_hs",
		"ControlExist" : "1", "ap_start" : "1", "ap_ready" : "1", "ap_done" : "1", "ap_continue" : "0", "ap_idle" : "1",
		"Pipeline" : "None", "UnalignedPipeline" : "0", "RewindPipeline" : "0", "ProcessNetwork" : "0",
		"II" : "0",
		"VariableLatency" : "1", "ExactLatency" : "-1", "EstimateLatencyMin" : "1", "EstimateLatencyMax" : "9",
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
			{"Name" : "act_buf_V_0", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_1", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_2", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_3", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_24", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_24", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_21", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_21", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_22", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_22", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_23", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_23", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_3", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_7", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_11", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_15", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_19", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_7", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_11", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_15", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_19", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_2", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_6", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_10", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_14", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_18", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_6", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_10", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_14", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_18", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_1", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_5", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_9", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_13", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_17", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_5", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_9", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_13", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_17", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_0", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_4", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_8", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_12", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_16", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_20", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_4", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_8", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_12", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_16", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_20", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "w_ptr", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "a_ptr", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "acc_reg_V", "Type" : "OVld", "Direction" : "IO"}]},
	{"ID" : "1", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U1", "Parent" : "0"},
	{"ID" : "2", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U2", "Parent" : "0"},
	{"ID" : "3", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U3", "Parent" : "0"},
	{"ID" : "4", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U4", "Parent" : "0"},
	{"ID" : "5", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U5", "Parent" : "0"},
	{"ID" : "6", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U6", "Parent" : "0"},
	{"ID" : "7", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U7", "Parent" : "0"},
	{"ID" : "8", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U8", "Parent" : "0"},
	{"ID" : "9", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U9", "Parent" : "0"}]}


set ArgLastReadFirstWriteLatency {
	CNN_ALU_Top {
		rs1_data_V {Type I LastRead 0 FirstWrite -1}
		cnn_op_V {Type I LastRead 0 FirstWrite -1}
		rd_data_V {Type O LastRead -1 FirstWrite 0}
		act_buf_V_0 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_1 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_2 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_3 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_24 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_24 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_21 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_21 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_22 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_22 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_23 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_23 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_3 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_7 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_11 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_15 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_19 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_7 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_11 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_15 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_19 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_2 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_6 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_10 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_14 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_18 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_6 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_10 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_14 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_18 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_1 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_5 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_9 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_13 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_17 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_5 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_9 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_13 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_17 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_0 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_4 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_8 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_12 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_16 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_20 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_4 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_8 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_12 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_16 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_20 {Type IO LastRead -1 FirstWrite -1}
		w_ptr {Type IO LastRead -1 FirstWrite -1}
		a_ptr {Type IO LastRead -1 FirstWrite -1}
		acc_reg_V {Type IO LastRead -1 FirstWrite -1}}}

set hasDtUnsupportedChannel 0

set PerformanceInfo {[
	{"Name" : "Latency", "Min" : "1", "Max" : "9"}
	, {"Name" : "Interval", "Min" : "2", "Max" : "10"}
]}

set PipelineEnableSignalInfo {[
	{"Pipeline" : "0", "EnableSignal" : "ap_enable_pp0"}
]}

set Spec2ImplPortList { 
	rs1_data_V { ap_none {  { rs1_data_V in_data 0 32 } } }
	cnn_op_V { ap_none {  { cnn_op_V in_data 0 3 } } }
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
	{ cnn_op_V int 3 regular  }
	{ rd_data_V int 32 regular {pointer 1}  }
}
set C_modelArgMapList {[ 
	{ "Name" : "rs1_data_V", "interface" : "wire", "bitwidth" : 32, "direction" : "READONLY", "bitSlice":[{"low":0,"up":31,"cElement": [{"cName": "rs1_data.V","cData": "uint32","bit_use": { "low": 0,"up": 31},"cArray": [{"low" : 0,"up" : 0,"step" : 0}]}]}]} , 
 	{ "Name" : "cnn_op_V", "interface" : "wire", "bitwidth" : 3, "direction" : "READONLY", "bitSlice":[{"low":0,"up":2,"cElement": [{"cName": "cnn_op.V","cData": "uint3","bit_use": { "low": 0,"up": 2},"cArray": [{"low" : 0,"up" : 0,"step" : 0}]}]}]} , 
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
	{ cnn_op_V sc_in sc_lv 3 signal 1 } 
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
 	{ "name": "cnn_op_V", "direction": "in", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "cnn_op_V", "role": "default" }} , 
 	{ "name": "rd_data_V", "direction": "out", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "rd_data_V", "role": "default" }}  ]}

set RtlHierarchyInfo {[
	{"ID" : "0", "Level" : "0", "Path" : "`AUTOTB_DUT_INST", "Parent" : "", "Child" : ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21"],
		"CDFG" : "CNN_ALU_Top",
		"Protocol" : "ap_ctrl_hs",
		"ControlExist" : "1", "ap_start" : "1", "ap_ready" : "1", "ap_done" : "1", "ap_continue" : "0", "ap_idle" : "1",
		"Pipeline" : "None", "UnalignedPipeline" : "0", "RewindPipeline" : "0", "ProcessNetwork" : "0",
		"II" : "0",
		"VariableLatency" : "1", "ExactLatency" : "-1", "EstimateLatencyMin" : "1", "EstimateLatencyMax" : "9",
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
	{"ID" : "2", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U2", "Parent" : "0"},
	{"ID" : "3", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U3", "Parent" : "0"},
	{"ID" : "4", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U4", "Parent" : "0"},
	{"ID" : "5", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U5", "Parent" : "0"},
	{"ID" : "6", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U6", "Parent" : "0"},
	{"ID" : "7", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U7", "Parent" : "0"},
	{"ID" : "8", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U8", "Parent" : "0"},
	{"ID" : "9", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U9", "Parent" : "0"},
	{"ID" : "10", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U10", "Parent" : "0"},
	{"ID" : "11", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U11", "Parent" : "0"},
	{"ID" : "12", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U12", "Parent" : "0"},
	{"ID" : "13", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U13", "Parent" : "0"},
	{"ID" : "14", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U14", "Parent" : "0"},
	{"ID" : "15", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U15", "Parent" : "0"},
	{"ID" : "16", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U16", "Parent" : "0"},
	{"ID" : "17", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U17", "Parent" : "0"},
	{"ID" : "18", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U18", "Parent" : "0"},
	{"ID" : "19", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_meOg_U19", "Parent" : "0"},
	{"ID" : "20", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U20", "Parent" : "0"},
	{"ID" : "21", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_meOg_U21", "Parent" : "0"}]}


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
	{"Name" : "Latency", "Min" : "1", "Max" : "9"}
	, {"Name" : "Interval", "Min" : "2", "Max" : "10"}
]}

set PipelineEnableSignalInfo {[
	{"Pipeline" : "0", "EnableSignal" : "ap_enable_pp0"}
	{"Pipeline" : "1", "EnableSignal" : "ap_enable_pp1"}
]}

set Spec2ImplPortList { 
	rs1_data_V { ap_none {  { rs1_data_V in_data 0 32 } } }
	cnn_op_V { ap_none {  { cnn_op_V in_data 0 3 } } }
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
	{"ID" : "0", "Level" : "0", "Path" : "`AUTOTB_DUT_INST", "Parent" : "", "Child" : ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21"],
		"CDFG" : "CNN_ALU_Top",
		"Protocol" : "ap_ctrl_hs",
		"ControlExist" : "1", "ap_start" : "1", "ap_ready" : "1", "ap_done" : "1", "ap_continue" : "0", "ap_idle" : "1",
		"Pipeline" : "None", "UnalignedPipeline" : "0", "RewindPipeline" : "0", "ProcessNetwork" : "0",
		"II" : "0",
		"VariableLatency" : "1", "ExactLatency" : "-1", "EstimateLatencyMin" : "1", "EstimateLatencyMax" : "9",
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
	{"ID" : "2", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U2", "Parent" : "0"},
	{"ID" : "3", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U3", "Parent" : "0"},
	{"ID" : "4", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U4", "Parent" : "0"},
	{"ID" : "5", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U5", "Parent" : "0"},
	{"ID" : "6", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U6", "Parent" : "0"},
	{"ID" : "7", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U7", "Parent" : "0"},
	{"ID" : "8", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U8", "Parent" : "0"},
	{"ID" : "9", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U9", "Parent" : "0"},
	{"ID" : "10", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U10", "Parent" : "0"},
	{"ID" : "11", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U11", "Parent" : "0"},
	{"ID" : "12", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U12", "Parent" : "0"},
	{"ID" : "13", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U13", "Parent" : "0"},
	{"ID" : "14", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U14", "Parent" : "0"},
	{"ID" : "15", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U15", "Parent" : "0"},
	{"ID" : "16", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U16", "Parent" : "0"},
	{"ID" : "17", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U17", "Parent" : "0"},
	{"ID" : "18", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U18", "Parent" : "0"},
	{"ID" : "19", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_meOg_U19", "Parent" : "0"},
	{"ID" : "20", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U20", "Parent" : "0"},
	{"ID" : "21", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_meOg_U21", "Parent" : "0"}]}


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
	{"Name" : "Latency", "Min" : "1", "Max" : "9"}
	, {"Name" : "Interval", "Min" : "2", "Max" : "10"}
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
	{"ID" : "0", "Level" : "0", "Path" : "`AUTOTB_DUT_INST", "Parent" : "", "Child" : ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31"],
		"CDFG" : "CNN_ALU_Top",
		"Protocol" : "ap_ctrl_hs",
		"ControlExist" : "1", "ap_start" : "1", "ap_ready" : "1", "ap_done" : "1", "ap_continue" : "0", "ap_idle" : "1",
		"Pipeline" : "None", "UnalignedPipeline" : "0", "RewindPipeline" : "0", "ProcessNetwork" : "0",
		"II" : "0",
		"VariableLatency" : "1", "ExactLatency" : "-1", "EstimateLatencyMin" : "1", "EstimateLatencyMax" : "2",
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
	{"ID" : "1", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mbkb_U1", "Parent" : "0"},
	{"ID" : "2", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mbkb_U2", "Parent" : "0"},
	{"ID" : "3", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mbkb_U3", "Parent" : "0"},
	{"ID" : "4", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mbkb_U4", "Parent" : "0"},
	{"ID" : "5", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mbkb_U5", "Parent" : "0"},
	{"ID" : "6", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mbkb_U6", "Parent" : "0"},
	{"ID" : "7", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mbkb_U7", "Parent" : "0"},
	{"ID" : "8", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mbkb_U8", "Parent" : "0"},
	{"ID" : "9", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mbkb_U9", "Parent" : "0"},
	{"ID" : "10", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mbkb_U10", "Parent" : "0"},
	{"ID" : "11", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mbkb_U11", "Parent" : "0"},
	{"ID" : "12", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mbkb_U12", "Parent" : "0"},
	{"ID" : "13", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mbkb_U13", "Parent" : "0"},
	{"ID" : "14", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mbkb_U14", "Parent" : "0"},
	{"ID" : "15", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mbkb_U15", "Parent" : "0"},
	{"ID" : "16", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mbkb_U16", "Parent" : "0"},
	{"ID" : "17", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mbkb_U17", "Parent" : "0"},
	{"ID" : "18", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mbkb_U18", "Parent" : "0"},
	{"ID" : "19", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U19", "Parent" : "0"},
	{"ID" : "20", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U20", "Parent" : "0"},
	{"ID" : "21", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mbkb_U21", "Parent" : "0"},
	{"ID" : "22", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U22", "Parent" : "0"},
	{"ID" : "23", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U23", "Parent" : "0"},
	{"ID" : "24", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U24", "Parent" : "0"},
	{"ID" : "25", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U25", "Parent" : "0"},
	{"ID" : "26", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U26", "Parent" : "0"},
	{"ID" : "27", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U27", "Parent" : "0"},
	{"ID" : "28", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U28", "Parent" : "0"},
	{"ID" : "29", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U29", "Parent" : "0"},
	{"ID" : "30", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U30", "Parent" : "0"},
	{"ID" : "31", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U31", "Parent" : "0"}]}


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
	{"Name" : "Latency", "Min" : "1", "Max" : "2"}
	, {"Name" : "Interval", "Min" : "2", "Max" : "3"}
]}

set PipelineEnableSignalInfo {[
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
	{"ID" : "0", "Level" : "0", "Path" : "`AUTOTB_DUT_INST", "Parent" : "", "Child" : ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20"],
		"CDFG" : "CNN_ALU_Top",
		"Protocol" : "ap_ctrl_hs",
		"ControlExist" : "1", "ap_start" : "1", "ap_ready" : "1", "ap_done" : "1", "ap_continue" : "0", "ap_idle" : "1",
		"Pipeline" : "None", "UnalignedPipeline" : "0", "RewindPipeline" : "0", "ProcessNetwork" : "0",
		"II" : "0",
		"VariableLatency" : "1", "ExactLatency" : "-1", "EstimateLatencyMin" : "1", "EstimateLatencyMax" : "10",
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
			{"Name" : "weight_buf_V_25", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_26", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_27", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_28", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_29", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_30", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_31", "Type" : "OVld", "Direction" : "IO"},
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
			{"Name" : "act_buf_V_25", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_26", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_27", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_28", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_29", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_30", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_31", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "acc_reg_V", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "w_ptr", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "a_ptr", "Type" : "OVld", "Direction" : "IO"}]},
	{"ID" : "1", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U1", "Parent" : "0"},
	{"ID" : "2", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U2", "Parent" : "0"},
	{"ID" : "3", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U3", "Parent" : "0"},
	{"ID" : "4", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U4", "Parent" : "0"},
	{"ID" : "5", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U5", "Parent" : "0"},
	{"ID" : "6", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U6", "Parent" : "0"},
	{"ID" : "7", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U7", "Parent" : "0"},
	{"ID" : "8", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U8", "Parent" : "0"},
	{"ID" : "9", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U9", "Parent" : "0"},
	{"ID" : "10", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U10", "Parent" : "0"},
	{"ID" : "11", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U11", "Parent" : "0"},
	{"ID" : "12", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U12", "Parent" : "0"},
	{"ID" : "13", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U13", "Parent" : "0"},
	{"ID" : "14", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U14", "Parent" : "0"},
	{"ID" : "15", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U15", "Parent" : "0"},
	{"ID" : "16", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U16", "Parent" : "0"},
	{"ID" : "17", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U17", "Parent" : "0"},
	{"ID" : "18", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U18", "Parent" : "0"},
	{"ID" : "19", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U19", "Parent" : "0"},
	{"ID" : "20", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mcud_U20", "Parent" : "0"}]}


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
		weight_buf_V_25 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_26 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_27 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_28 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_29 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_30 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_31 {Type IO LastRead -1 FirstWrite -1}
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
		act_buf_V_25 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_26 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_27 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_28 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_29 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_30 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_31 {Type IO LastRead -1 FirstWrite -1}
		acc_reg_V {Type IO LastRead -1 FirstWrite -1}
		w_ptr {Type IO LastRead -1 FirstWrite -1}
		a_ptr {Type IO LastRead -1 FirstWrite -1}}}

set hasDtUnsupportedChannel 0

set PerformanceInfo {[
	{"Name" : "Latency", "Min" : "1", "Max" : "10"}
	, {"Name" : "Interval", "Min" : "2", "Max" : "11"}
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
	{"ID" : "0", "Level" : "0", "Path" : "`AUTOTB_DUT_INST", "Parent" : "", "Child" : ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24"],
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
			{"Name" : "weight_buf_V_25", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_26", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_27", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_28", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_29", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_30", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "weight_buf_V_31", "Type" : "OVld", "Direction" : "IO"},
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
			{"Name" : "act_buf_V_25", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_26", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_27", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_28", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_29", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_30", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "act_buf_V_31", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "acc_reg_V", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "w_ptr", "Type" : "OVld", "Direction" : "IO"},
			{"Name" : "a_ptr", "Type" : "OVld", "Direction" : "IO"}]},
	{"ID" : "1", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U1", "Parent" : "0"},
	{"ID" : "2", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U2", "Parent" : "0"},
	{"ID" : "3", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U3", "Parent" : "0"},
	{"ID" : "4", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U4", "Parent" : "0"},
	{"ID" : "5", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U5", "Parent" : "0"},
	{"ID" : "6", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U6", "Parent" : "0"},
	{"ID" : "7", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U7", "Parent" : "0"},
	{"ID" : "8", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U8", "Parent" : "0"},
	{"ID" : "9", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U9", "Parent" : "0"},
	{"ID" : "10", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_3bkb_U10", "Parent" : "0"},
	{"ID" : "11", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U11", "Parent" : "0"},
	{"ID" : "12", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U12", "Parent" : "0"},
	{"ID" : "13", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U13", "Parent" : "0"},
	{"ID" : "14", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U14", "Parent" : "0"},
	{"ID" : "15", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U15", "Parent" : "0"},
	{"ID" : "16", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mux_8cud_U16", "Parent" : "0"},
	{"ID" : "17", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U17", "Parent" : "0"},
	{"ID" : "18", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U18", "Parent" : "0"},
	{"ID" : "19", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U19", "Parent" : "0"},
	{"ID" : "20", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U20", "Parent" : "0"},
	{"ID" : "21", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U21", "Parent" : "0"},
	{"ID" : "22", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U22", "Parent" : "0"},
	{"ID" : "23", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U23", "Parent" : "0"},
	{"ID" : "24", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.CNN_ALU_Top_mac_mdEe_U24", "Parent" : "0"}]}


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
		weight_buf_V_25 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_26 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_27 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_28 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_29 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_30 {Type IO LastRead -1 FirstWrite -1}
		weight_buf_V_31 {Type IO LastRead -1 FirstWrite -1}
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
		act_buf_V_25 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_26 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_27 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_28 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_29 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_30 {Type IO LastRead -1 FirstWrite -1}
		act_buf_V_31 {Type IO LastRead -1 FirstWrite -1}
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
