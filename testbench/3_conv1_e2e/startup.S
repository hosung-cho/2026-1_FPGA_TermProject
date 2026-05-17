.section .text.init
.global _start
_start:
    # Set stack pointer (end of 32KB RAM starting at 0x8000 -> 0x00010000)
    li sp, 0x00010000
    # Call main
    jal ra, main
    # Loop forever (halting condition)
    jal x0, .
