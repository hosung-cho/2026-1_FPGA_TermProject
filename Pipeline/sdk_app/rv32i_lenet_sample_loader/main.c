#include "platform.h"
#include "xil_io.h"
#include "xil_printf.h"
#include "lenet_samples.h"

#define RV32I_AXI_BASEADDR      0x43C00000u

#define RV32I_REG_CONTROL       0x0000u
#define RV32I_REG_STATUS        0x0004u
#define RV32I_REG_PREDICTED     0x0008u
#define RV32I_REG_EXPECTED      0x000Cu
#define RV32I_REG_HEARTBEAT     0x0010u
#define RV32I_REG_DEBUG_PC      0x0014u

#define RV32I_SAMPLE_INPUT      0x1000u
#define RV32I_SAMPLE_EXPECTED   0x2000u

#define RV32I_CONTROL_RUN       0x00000001u
#define RV32I_CONTROL_CLEAR     0x00000002u

#define RV32I_STATUS_DONE       0x00000001u
#define RV32I_STATUS_PASS       0x00000002u
#define RV32I_STATUS_FAIL       0x00000004u

#define SAMPLE_WORDS            256u
#define POLL_LIMIT              20000000u

static inline u32 rv32i_read(u32 offset)
{
    return Xil_In32(RV32I_AXI_BASEADDR + offset);
}

static inline void rv32i_write(u32 offset, u32 value)
{
    Xil_Out32(RV32I_AXI_BASEADDR + offset, value);
}

static void rv32i_load_sample(const u32 *sample_words, u32 expected)
{
    u32 i;

    rv32i_write(RV32I_REG_CONTROL, RV32I_CONTROL_CLEAR);
    rv32i_write(RV32I_REG_CONTROL, 0u);

    for (i = 0u; i < SAMPLE_WORDS; i++) {
        rv32i_write(RV32I_SAMPLE_INPUT + (i * 4u), sample_words[i]);
    }
    rv32i_write(RV32I_SAMPLE_EXPECTED, expected);
}

static int rv32i_run_one(unsigned sample_index)
{
    u32 i;
    u32 status;
    u32 predicted;
    u32 expected;

    rv32i_load_sample(lenet_sample_words[sample_index],
                      lenet_sample_expected[sample_index]);

    rv32i_write(RV32I_REG_CONTROL, RV32I_CONTROL_RUN);

    for (i = 0u; i < POLL_LIMIT; i++) {
        status = rv32i_read(RV32I_REG_STATUS);
        if ((status & RV32I_STATUS_DONE) != 0u) {
            predicted = rv32i_read(RV32I_REG_PREDICTED);
            expected = rv32i_read(RV32I_REG_EXPECTED);

            xil_printf("sample=%d status=0x%08x predicted=%d expected=%d pc=0x%08x\r\n",
                       sample_index, status, predicted, expected,
                       rv32i_read(RV32I_REG_DEBUG_PC));

            if ((status & RV32I_STATUS_PASS) != 0u) {
                return 0;
            }
            if ((status & RV32I_STATUS_FAIL) != 0u) {
                return 1;
            }
            return 2;
        }
    }

    xil_printf("sample=%d TIMEOUT status=0x%08x heartbeat=%d pc=0x%08x\r\n",
               sample_index,
               rv32i_read(RV32I_REG_STATUS),
               rv32i_read(RV32I_REG_HEARTBEAT),
               rv32i_read(RV32I_REG_DEBUG_PC));
    return 3;
}

int main(void)
{
    unsigned i;
    unsigned pass_count = 0u;

    init_platform();

    xil_printf("\r\nRV32I LeNet sample-loader test start\r\n");
    xil_printf("base=0x%08x samples=%d\r\n", RV32I_AXI_BASEADDR, LENET_SAMPLE_COUNT);

    for (i = 0u; i < LENET_SAMPLE_COUNT; i++) {
        if (rv32i_run_one(i) == 0) {
            pass_count++;
            xil_printf("sample=%d PASS\r\n", i);
        } else {
            xil_printf("sample=%d FAIL\r\n", i);
        }
    }

    xil_printf("summary pass=%d total=%d\r\n", pass_count, LENET_SAMPLE_COUNT);

    cleanup_platform();
    return (pass_count == LENET_SAMPLE_COUNT) ? 0 : 1;
}
