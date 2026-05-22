#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xil_cache.h"
#include "sleep.h"

// Base addresses from Vivado Address Editor
#define IMEM_BRAM_BASE ((UINTPTR)0x40000000U)
#define DMEM_BRAM_BASE ((UINTPTR)0x42000000U)
#define GPIO_BASE      ((UINTPTR)0x41200000U)

// Address ranges (bytes)
#define IMEM_RANGE_BYTES (8U * 1024U)
#define DMEM_RANGE_BYTES (64U * 1024U)

// AXI GPIO register offsets
#define GPIO_DATA_OFFSET 0x0U
#define GPIO_TRI_OFFSET  0x4U

// Reset polarity: active-low
#define RESET_ASSERT_VALUE   0x0U
#define RESET_DEASSERT_VALUE 0x1U

// Status block layout in DMEM (matches link.ld .status_section placement)
#define STATUS_OFFSET        0x00008000U
#define PRED_LABEL_OFFSET    (STATUS_OFFSET + 0x4U)
#define STATUS_DONE_VALUE    0x12345678U

// TODO: Replace these with arrays generated from imem.hex/dmem.hex.
static const u32 imem_image[] = { 0x00000013U };
static const u32 dmem_image[] = { 0x00000000U };

#define IMEM_IMAGE_WORDS ((u32)(sizeof(imem_image) / sizeof(imem_image[0])))
#define DMEM_IMAGE_WORDS ((u32)(sizeof(dmem_image) / sizeof(dmem_image[0])))

static void load_bram(UINTPTR base, const u32 *data, u32 word_count, u32 range_bytes) {
    u32 max_words = range_bytes / 4U;
    if (word_count > max_words) {
        word_count = max_words;
    }
    for (u32 i = 0; i < word_count; ++i) {
        Xil_Out32(base + (i * 4U), data[i]);
    }
}

static void gpio_reset_init(void) {
    // AXI GPIO: 0 = output, 1 = input
    Xil_Out32(GPIO_BASE + GPIO_TRI_OFFSET, 0x00000000U);
}

static void gpio_reset_write(u32 value) {
    Xil_Out32(GPIO_BASE + GPIO_DATA_OFFSET, value);
}

static void reset_pulse(void) {
    gpio_reset_write(RESET_ASSERT_VALUE);
    usleep(10);
    gpio_reset_write(RESET_DEASSERT_VALUE);
}

static void dump_dmem_words(UINTPTR base, u32 start_word, u32 count) {
    for (u32 i = 0; i < count; ++i) {
        u32 value = Xil_In32(base + ((start_word + i) * 4U));
        xil_printf("[DMEM] 0x%08x = 0x%08x\n\r", (unsigned)(base + ((start_word + i) * 4U)), value);
    }
}

int main(void) {
    init_platform();
    xil_printf("[Host] Zynq BRAM loader start\n\r");

    if (STATUS_OFFSET + 8U > DMEM_RANGE_BYTES) {
        xil_printf("[Host] Warning: STATUS_OFFSET exceeds DMEM_RANGE_BYTES. Update ranges or offsets.\n\r");
    }

    gpio_reset_init();
    gpio_reset_write(RESET_ASSERT_VALUE);

    xil_printf("[Host] Loading IMEM (%lu words)\n\r", (unsigned long)IMEM_IMAGE_WORDS);
    load_bram(IMEM_BRAM_BASE, imem_image, IMEM_IMAGE_WORDS, IMEM_RANGE_BYTES);

    xil_printf("[Host] Loading DMEM (%lu words)\n\r", (unsigned long)DMEM_IMAGE_WORDS);
    load_bram(DMEM_BRAM_BASE, dmem_image, DMEM_IMAGE_WORDS, DMEM_RANGE_BYTES);

    // Ensure PS writes reach BRAM before releasing reset
    Xil_DCacheFlushRange(IMEM_BRAM_BASE, IMEM_RANGE_BYTES);
    Xil_DCacheFlushRange(DMEM_BRAM_BASE, DMEM_RANGE_BYTES);

    xil_printf("[Host] Releasing reset\n\r");
    reset_pulse();

    xil_printf("[Host] Polling status...\n\r");
    u32 status = 0U;
    const u32 max_poll = 1000000U;
    for (u32 i = 0; i < max_poll; ++i) {
        Xil_DCacheInvalidateRange(DMEM_BRAM_BASE + STATUS_OFFSET, 64U);
        status = Xil_In32(DMEM_BRAM_BASE + STATUS_OFFSET);
        if (status == STATUS_DONE_VALUE) {
            break;
        }
        if ((i % 10000U) == 0U) {
            usleep(100);
        }
    }

    if (status == STATUS_DONE_VALUE) {
        u32 label = Xil_In32(DMEM_BRAM_BASE + PRED_LABEL_OFFSET);
        xil_printf("[Host] DONE: status=0x%08x, predicted=%lu\n\r", status, (unsigned long)label);
    } else {
        xil_printf("[Host] TIMEOUT: status=0x%08x\n\r", status);
        dump_dmem_words(DMEM_BRAM_BASE, 0U, 16U);
    }

    cleanup_platform();
    return 0;
}
