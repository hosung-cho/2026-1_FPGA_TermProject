#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xil_cache.h"
#include "sleep.h"

#define IMEM_BRAM_BASE ((UINTPTR)0x00A0000000U)
#define DMEM_BRAM_BASE ((UINTPTR)0x00A2000000U)

// Tiny RV32I program that exercises byte-lane writes.
// Expected final DMEM word at offset 0x0 is 0x44332211 on a correct 32-bit little-endian BRAM path.
static const u32 imem_image[] = {
    0x01100093U, // addi x1, x0, 0x11
    0x00100023U, // sb   x1, 0(x0)
    0x02200093U, // addi x1, x0, 0x22
    0x001000A3U, // sb   x1, 1(x0)
    0x03300093U, // addi x1, x0, 0x33
    0x00100123U, // sb   x1, 2(x0)
    0x04400093U, // addi x1, x0, 0x44
    0x001001A3U, // sb   x1, 3(x0)
    0x00002283U, // lw   x5, 0(x0)
    0x00502423U, // sw   x5, 8(x0)
    0x0000006FU, // jal  x0, 0
};

static const u32 dmem_image[] = {
    0x00000000U,
    0x00000000U,
    0x00000000U,
    0x00000000U,
};

#define IMEM_IMAGE_WORDS ((u32)(sizeof(imem_image) / sizeof(imem_image[0])))
#define DMEM_IMAGE_WORDS ((u32)(sizeof(dmem_image) / sizeof(dmem_image[0])))

#define RESET_ASSERT_VALUE   0x0U
#define RESET_DEASSERT_VALUE 0x1U
#define GPIO_BASE            ((UINTPTR)0x00A3000000U)
#define GPIO_DATA_OFFSET     0x0U

static void gpio_reset_write(u32 value) {
    xil_printf("[Probe] reset=0x%08x\n\r", value);
    Xil_Out32(GPIO_BASE + GPIO_DATA_OFFSET, value);
}

static void reset_pulse(void) {
    gpio_reset_write(RESET_ASSERT_VALUE);
    usleep(10);
    gpio_reset_write(RESET_DEASSERT_VALUE);
}

static void load_words(UINTPTR base, const u32 *data, u32 word_count) {
    for (u32 i = 0U; i < word_count; ++i) {
        Xil_Out32(base + (i * 4U), data[i]);
    }
}

static void dump_words(UINTPTR base, u32 start_word, u32 count) {
    for (u32 i = 0U; i < count; ++i) {
        UINTPTR addr = base + ((start_word + i) * 4U);
        xil_printf("[Probe] 0x%08x = 0x%08x\n\r", (unsigned)addr, (unsigned)Xil_In32(addr));
    }
}

int main(void) {
    init_platform();

    xil_printf("=== Ultra96 RV32I BRAM Width Probe ===\n\r");
    xil_printf("Expected ILA store pattern: sb -> ByteEnable 0001/0010/0100/1000, lw -> 1111 on read path.\n\r");

    gpio_reset_write(RESET_ASSERT_VALUE);
    load_words(IMEM_BRAM_BASE, imem_image, IMEM_IMAGE_WORDS);
    load_words(DMEM_BRAM_BASE, dmem_image, DMEM_IMAGE_WORDS);
    Xil_DCacheFlushRange(IMEM_BRAM_BASE, IMEM_IMAGE_WORDS * 4U);
    Xil_DCacheFlushRange(DMEM_BRAM_BASE, DMEM_IMAGE_WORDS * 4U);

    xil_printf("[Probe] IMEM loaded: %lu words\n\r", (unsigned long)IMEM_IMAGE_WORDS);
    xil_printf("[Probe] DMEM before run:\n\r");
    dump_words(DMEM_BRAM_BASE, 0U, 4U);

    reset_pulse();

    for (u32 i = 0U; i < 1000000U; ++i) {
        Xil_DCacheInvalidateRange(DMEM_BRAM_BASE, 16U);
        if (Xil_In32(DMEM_BRAM_BASE + 0x0U) == 0x44332211U) {
            break;
        }
        if ((i % 10000U) == 0U) {
            usleep(1);
        }
    }

    Xil_DCacheInvalidateRange(DMEM_BRAM_BASE, 32U);
    xil_printf("[Probe] DMEM after run:\n\r");
    dump_words(DMEM_BRAM_BASE, 0U, 4U);

    xil_printf("[Probe] PASS if word0=0x44332211 and word2=0x44332211.\n\r");
    cleanup_platform();
    return 0;
}