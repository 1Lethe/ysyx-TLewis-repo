ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }

MEMORY {
  mrom(rx)  : ORIGIN = 0x20000000, LENGTH = 4K
  flash(rx) : ORIGIN = 0x30000000, LENGTH = 16M
  sram(rwx) : ORIGIN = 0x0f000000, LENGTH = 8K
}

SECTIONS {
  . = ORIGIN(flash) + _entry_offset;
  .text : {
    *(entry)
    *(.text*)
  } > flash AT > flash : text
  etext = .;
  _etext = .;

  .rodata : {
    *(.rodata*)
  } > flash AT > flash : text

  . = ORIGIN(sram);
  .data : {
  . = ALIGN(4);
  _data_vma_start = .;
    *(.data*)
    *(.sdata*)
  . = ALIGN(4);
  _data_vma_end = .;
  } > sram AT > flash : data
  _data_lma_start = LOADADDR(.data);
  edata = .;
  _data = .;

  .bss : {
  . = ALIGN(4);
	_bss_vma_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  . = ALIGN(4);
  _bss_vma_end = .;
  } > sram AT > flash : data

  . = ALIGN(4);
  _heap_start = .;
  . = _heap_start + _heap_size;
  _heap_end = . ;
  end = .;
  _end = .;

  _stack_top = ORIGIN(sram) + LENGTH(sram);
  . = ALIGN(16);
  _stack_bottom = .;
  _stack_size = _stack_top - _stack_bottom;
  . = _stack_top;
  _stack_pointer = .;
}
