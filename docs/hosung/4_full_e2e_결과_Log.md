============================================================
  LeNet-5 Full Network End-to-End RTL Verification
  [Conv1 -> Pool1 -> Conv2 -> Pool2 -> FC1 -> FC2 -> FC3]
============================================================

[INFO] Simulation started. Running LeNet-5 inference on MNIST Image 0 (label=7)...
[INFO] CPU halted at PC=0x00000008

--- Verification Results ---
Total Cycles: 1335927
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
  *** LENET5 FULL E2E VERIFICATION PASSED ***
  RTL CFU matching PyTorch Golden outputs perfectly!
  Predicted Label: 7 (Correct!)
============================================================
$finish called at time : 13359295 ns : File "C:/Disk_C_Ho/26_1_FPGA_Design/2026-1_FPGA_TermProject/testbench/4_full_e2e/lenet5_e2e_tb.v" Line 160
run: Time (s): cpu = 00:00:01 ; elapsed = 00:00:25 . Memory (MB): peak = 399.594 ; gain = 0.000
xsim: Time (s): cpu = 00:00:01 ; elapsed = 00:00:26 . Memory (MB): peak = 399.594 ; gain = 6.785
INFO: [USF-XSim-96] XSim completed. Design snapshot 'lenet5_e2e_tb_behav' loaded.
INFO: [USF-XSim-97] XSim simulation ran for all
launch_simulation: Time (s): cpu = 00:00:01 ; elapsed = 00:00:35 . Memory (MB): peak = 399.594 ; gain = 11.043