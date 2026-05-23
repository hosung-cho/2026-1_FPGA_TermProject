.section .text.init
.global _start
_start:
    # Set stack pointer (end of 64KB RAM starting at 0x8000 -> 0x00018000)
    li sp, 0x00018000
    # Call main
    jal ra, main
    # Loop forever (halting condition)
    jal x0, .
