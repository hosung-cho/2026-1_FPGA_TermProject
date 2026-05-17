MEMORY
{
  rom (rx)  : ORIGIN = 0x00000000, LENGTH = 16K
  ram (rwx) : ORIGIN = 0x00008000, LENGTH = 32K
}

SECTIONS
{
  .text : {
    *(.text.init)
    *(.text)
    *(.text.*)
  } > rom

  .data : {
    *(.status_section)
    *(.data)
    *(.data.*)
    *(.rodata)
    *(.rodata.*)
    *(.sdata)
    *(.sdata.*)
  } > ram

  .bss : {
    *(.bss)
    *(.bss.*)
    *(.sbss)
    *(.sbss.*)
  } > ram
}
