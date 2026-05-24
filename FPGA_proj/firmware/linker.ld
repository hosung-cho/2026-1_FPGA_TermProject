ENTRY(_start)

MEMORY
{
  imem (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
  dmem (rwx) : ORIGIN = 0x00011000, LENGTH = 60K
}

SECTIONS
{
  .text : {
    *(.text.start)
    *(.text*)
    *(.rodata*)
  } > imem

  .data : {
    *(.sdata*)
    *(.data*)
  } > dmem AT > imem

  .bss (NOLOAD) : {
    *(.sbss*)
    *(.bss*)
    *(COMMON)
  } > dmem

  . = ORIGIN(dmem) + LENGTH(dmem);
  _stack_top = .;
}
