============================================================
  LeNet-5 Pure SW-Only (RV32I Baseline) RTL Verification
============================================================

[INFO] Simulation started. Running LeNet-5 SW-only inference on MNIST Image 0 (label=7)...
[INFO] CPU halted at PC=0x00000008

--- Verification Results (SW-Only Baseline) ---
Total Cycles: 40853500
Status Value (dmem[0]): 0x12345678
Predicted Label (dmem[1]): 7

--- Raw Class Scores (dmem[2] ~ dmem[11]) ---
Class 0:       -7326
Class 1:       -1701
Class 2:        7107
Class 3:       12536
Class 4:      -27280
Class 5:       -8113
Class 6:      -58487
Class 7:       47360
Class 8:       -7323
Class 9:       10389

============================================================
  *** LENET5 SW-ONLY VERIFICATION PASSED ***
  Predicted Label: 7 (Correct!)
============================================================
$finish called at time : 408535025 ns : File "C:/Disk_C_Ho/26_1_FPGA_Design/2026-1_FPGA_TermProject/testbench/5_sw_only/lenet5_sw_tb.v" Line 143
run: Time (s): cpu = 00:00:44 ; elapsed = 00:13:15 . Memory (MB): peak = 407.770 ; gain = 0.000
xsim: Time (s): cpu = 00:00:44 ; elapsed = 00:13:17 . Memory (MB): peak = 407.770 ; gain = 14.945
INFO: [USF-XSim-96] XSim completed. Design snapshot 'lenet5_sw_tb_behav' loaded.
INFO: [USF-XSim-97] XSim simulation ran for all
launch_simulation: Time (s): cpu = 00:00:44 ; elapsed = 00:13:28 . Memory (MB): peak = 407.770 ; gain = 19.121