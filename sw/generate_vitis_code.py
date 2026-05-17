import os

def hex_to_c_array_content(filename):
    with open(filename, 'r') as f:
        lines = f.readlines()
    
    out_lines = []
    for line in lines:
        line = line.strip()
        if line.startswith('@') or not line:
            continue
        words = line.split()
        for word in words:
            out_lines.append(f"    0x{word},")
    return "\n".join(out_lines)

def main():
    imem_path = 'testbench/4_full_e2e/imem.hex'
    dmem_path = 'testbench/4_full_e2e/dmem.hex'
    vitis_output = 'RV32I_FPGA/Single_cycle/260511_Single_AXI_BRAM/Vitis/vitis_lenet5.c'

    if not os.path.exists(imem_path) or not os.path.exists(dmem_path):
        print("Error: Hex files not found. Please compile the E2E testbench first.")
        return

    print("Converting imem.hex...")
    imem_content = hex_to_c_array_content(imem_path)
    imem_len = len(imem_content.splitlines())

    print("Converting dmem.hex...")
    dmem_content = hex_to_c_array_content(dmem_path)
    dmem_len = len(dmem_content.splitlines())

    c_code = f"""#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"       // I/O functions
#include "xparameters.h"  // Hardware parameters
#include "xil_cache.h"    // Cache control
#include "sleep.h"

// 1. Vivado Address Editor base addresses
#define INST_BRAM_BASE 0xA0000000  // Instruction BRAM (axi_bram_ctrl_0)
#define DATA_BRAM_BASE 0xA0010000  // Data BRAM (axi_bram_ctrl_1)

// 2. LeNet-5 ROM (Instruction) array size: {imem_len} words
const u32 inst_array[] = {{
{imem_content}
}};

// 3. LeNet-5 RAM (Data) array size: {dmem_len} words
const u32 data_array[] = {{
{dmem_content}
}};

int main() {{
    init_platform();
    xil_printf("====================================================\\n\\r");
    xil_printf("  RISC-V LeNet-5 FPGA Porting & Host Controller  \\n\\r");
    xil_printf("====================================================\\n\\r");

    // [Step 1] Load instructions into INST BRAM
    xil_printf("[Host] Loading Instructions ({imem_len} words)...\\n\\r");
    for(int i = 0; i < {imem_len}; i++) {{
        Xil_Out32(INST_BRAM_BASE + (i * 4), inst_array[i]);
    }}

    // [Step 2] Load weights and image data into DATA BRAM
    xil_printf("[Host] Loading Weights and Data ({dmem_len} words)...\\n\\r");
    for(int i = 0; i < {dmem_len}; i++) {{
        Xil_Out32(DATA_BRAM_BASE + (i * 4), data_array[i]);
    }}

    // [Step 3] Flush Data Cache (essential for Zynq system)
    Xil_DCacheFlush();
    xil_printf("[Host] Memory Setup Complete!\\n\\r");
    xil_printf("[Host] >>> PLEASE RELEASE CPU RESET IN VIVADO VIO OR GPIO <<<\\n\\r");
    
    xil_printf("[Host] Press ENTER once the inference is done to read results...\\n\\r");
    getchar(); 

    // [Step 4] Read Results from BRAM Status Block
    // Address mapping to s_block starting at Data BRAM offset 0x0
    u32 status = Xil_In32(DATA_BRAM_BASE + 0x00);
    u32 predicted_label = Xil_In32(DATA_BRAM_BASE + 0x04);
    
    xil_printf("----------------------------------------------------\\n\\r");
    xil_printf("                  Inference Results                 \\n\\r");
    xil_printf("----------------------------------------------------\\n\\r");
    xil_printf("  Status:          0x%08x\\n\\r", status);
    xil_printf("  Predicted Label: %d\\n\\r", predicted_label);
    xil_printf("\\n\\r");

    xil_printf("  --- Raw Class Scores ---\\n\\r");
    for(int i = 0; i < 10; i++) {{
        s32 score = (s32)Xil_In32(DATA_BRAM_BASE + 0x08 + (i * 4));
        xil_printf("  Class %d: %d\\n\\r", i, score);
    }}
    xil_printf("----------------------------------------------------\\n\\r");

    if (status == 0x12345678) {{
        xil_printf("  *** SUCCESS: LeNet-5 FPGA Inference Passed! ***\\n\\r");
    }} else if (status == 0xDEADBEEF) {{
        xil_printf("  *** ERROR: Inference Failed (Label Mismatch) ***\\n\\r");
    }} else {{
        xil_printf("  *** WARNING: Unknown Status (CPU still running or hung) ***\\n\\r");
    }}
    xil_printf("====================================================\\n\\r");

    cleanup_platform();
    return 0;
}}
"""

    with open(vitis_output, 'w') as f:
        f.write(c_code)
    print(f"Successfully generated: {vitis_output}")

if __name__ == '__main__':
    main()
