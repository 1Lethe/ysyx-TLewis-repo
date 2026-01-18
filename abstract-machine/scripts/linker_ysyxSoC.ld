ENTRY(_fsbl_main)

MEMORY {
  mrom(rx)   : ORIGIN = 0x20000000, LENGTH = 4K
  flash(rx)  : ORIGIN = 0x30000000, LENGTH = 16M
  sram(rwx)  : ORIGIN = 0x0f000000, LENGTH = 8K
  psram(rwx) : ORIGIN = 0x80000000, LENGTH = 4M
}

SECTIONS {

  . = ORIGIN(flash) + _entry_offset;
  .fsbl : {
    KEEP(*(.fsbl.entry))
  } > flash AT > flash

  . = ORIGIN(sram);
  .ssbl : {
    _ssbl_vma_start = .;
    KEEP(*(.ssbl.entry))
    . = ALIGN(8);
    _ssbl_vma_end = .;
  } > sram AT > flash
  _ssbl_lma_start = LOADADDR(.ssbl);

  . = ALIGN(16);
  _stack_bottom = .;
  . = ORIGIN(sram) + LENGTH(sram);
  _stack_top = .;
  _stack_pointer = .;

  . = ORIGIN(psram);

  .text : {
    _text_vma_start = .;
    *(.text*)
    . = ALIGN(8);
    _text_vma_end = .;
  } > psram AT > flash
  _text_lma_start = LOADADDR(.text);

  .rodata : {
    _rodata_vma_start = .;
    *(.rodata*)
    *(.srodata*)
    . = ALIGN(8);
    _rodata_vma_end = .;
  } > psram AT > flash
  _rodata_lma_start = LOADADDR(.rodata);

  .data : {
    _data_vma_start = .;
    *(.data*)
    *(.sdata*)
    . = ALIGN(8);
    _data_vma_end = .;
  } > psram AT > flash
  _data_lma_start = LOADADDR(.data);
  edata = .;
  _data = .;

  .bss : {
    _bss_vma_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
    . = ALIGN(8);
    _bss_vma_end = .;
  } > psram

  . = ALIGN(8);
  _heap_start = .;
  . = ORIGIN(psram) + LENGTH(psram);
  _heap_end = ORIGIN(psram) + LENGTH(psram);
  end = .;
  _end = .;
}
