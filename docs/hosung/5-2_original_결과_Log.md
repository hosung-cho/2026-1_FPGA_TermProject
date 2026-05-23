Time resolution is 1 ns
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
$finish called at time : 408535025 ns : File "/home/hosung/Ho/2026-1_FPGA_Design/2026-1_FPGA_TermProject/testbench/5-2_original/lenet5_sw_tb.v" Line 143
INFO: xsimkernel Simulation Memory Usage: 266744 KB (Peak: 319916 KB), Simulation CPU Usage: 497700 ms
