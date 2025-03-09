OUTPUT_ARCH( "riscv" )
ENTRY(init_stack)

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
