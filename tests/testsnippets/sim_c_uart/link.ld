OUTPUT_ARCH( "riscv" )
ENTRY(_start)

SECTIONS
{
  . = 0x00000000;
  .text :
  {
    *(.text.init)
    *(.text)
    *(.data)
    *(.data.string)
    *(.bss)
    _end = .;
  }
}
