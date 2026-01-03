ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }

SECTIONS {
  . = _sram_start;
  .data : {
    *(.data)
  } : data
  edata = .;
  _data = .;
  .bss : {
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  }

  . = ALIGN(4);
  _heap_start = .;
  . = _heap_start + _heap_size;
  _heap_end = . ;
  end = .;
  _end = .;

  _stack_top = _sram_end;
  . = ALIGN(16);
  _stack_bottom = .;
  _stack_size = _stack_top - _stack_bottom;
  . = _stack_top;
  _stack_pointer = .;

  . = _mrom_start + _entry_offset;
  .text : {
    *(entry)
    *(.text*)
  } : text
  etext = .;
  _etext = .;
  .rodata : {
    *(.rodata*)
  }
}
