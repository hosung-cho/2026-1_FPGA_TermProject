#include "platform.h"
#include "xil_io.h"
#include "xil_printf.h"

#define RV32I_AXI_BASEADDR      0x43C00000u

#define RV32I_REG_CONTROL       0x00u
#define RV32I_REG_STATUS        0x04u
#define RV32I_REG_PREDICTED     0x08u
#define RV32I_REG_EXPECTED      0x0Cu
#define RV32I_REG_HEARTBEAT     0x10u
#define RV32I_REG_DEBUG_PC      0x14u
#define RV32I_REG_DEBUG_INST    0x18u
#define RV32I_REG_DEBUG_ADDR    0x1Cu
#define RV32I_REG_DEBUG_RDATA   0x20u
#define RV32I_REG_DEBUG_WDATA   0x24u
#define RV32I_REG_DEBUG_WE      0x28u

#define RV32I_CONTROL_RUN       0x00000001u
#define RV32I_CONTROL_CLEAR     0x00000002u

#define RV32I_STATUS_DONE       0x00000001u
#define RV32I_STATUS_PASS       0x00000002u
#define RV32I_STATUS_FAIL       0x00000004u

#define POLL_LIMIT              20000000u
#define PRINT_EVERY             1000000u

static inline u32 rv32i_read(u32 offset)
{
    return Xil_In32(RV32I_AXI_BASEADDR + offset);
}

static inline void rv32i_write(u32 offset, u32 value)
{
    Xil_Out32(RV32I_AXI_BASEADDR + offset, value);
}

static void rv32i_print_debug(void)
{
    xil_printf("heartbeat=%d pc=0x%08x inst=0x%08x addr=0x%08x we=%d\r\n",
               rv32i_read(RV32I_REG_HEARTBEAT),
               rv32i_read(RV32I_REG_DEBUG_PC),
               rv32i_read(RV32I_REG_DEBUG_INST),
               rv32i_read(RV32I_REG_DEBUG_ADDR),
               rv32i_read(RV32I_REG_DEBUG_WE));
}

int main(void)
{
    u32 i;
    u32 status;
    u32 predicted;
    u32 expected;

    init_platform();

    xil_printf("\r\nRV32I LeNet AXI-Lite test start\r\n");
    xil_printf("base=0x%08x\r\n", (u32)RV32I_AXI_BASEADDR);

    rv32i_write(RV32I_REG_CONTROL, RV32I_CONTROL_CLEAR);
    rv32i_write(RV32I_REG_CONTROL, 0u);
    rv32i_write(RV32I_REG_CONTROL, RV32I_CONTROL_RUN);

    for (i = 0u; i < POLL_LIMIT; i++) {
        status = rv32i_read(RV32I_REG_STATUS);

        if ((status & RV32I_STATUS_DONE) != 0u) {
            predicted = rv32i_read(RV32I_REG_PREDICTED);
            expected = rv32i_read(RV32I_REG_EXPECTED);

            xil_printf("done status=0x%08x predicted=%d expected=%d\r\n",
                       status, predicted, expected);
            rv32i_print_debug();

            if ((status & RV32I_STATUS_PASS) != 0u) {
                xil_printf("PASS\r\n");
            } else if ((status & RV32I_STATUS_FAIL) != 0u) {
                xil_printf("FAIL\r\n");
            } else {
                xil_printf("DONE without pass/fail bit\r\n");
            }

            cleanup_platform();
            return 0;
        }

        if ((i % PRINT_EVERY) == 0u) {
            xil_printf("poll=%d status=0x%08x ", i, status);
            rv32i_print_debug();
        }
    }

    xil_printf("TIMEOUT status=0x%08x predicted=%d expected=%d\r\n",
               rv32i_read(RV32I_REG_STATUS),
               rv32i_read(RV32I_REG_PREDICTED),
               rv32i_read(RV32I_REG_EXPECTED));
    rv32i_print_debug();

    cleanup_platform();
    return 1;
}
