ENTRY(_start)
PHDRS { 
  fsbl PT_LOAD;
  ssbl PT_LOAD;
  text PT_LOAD; 
  data PT_LOAD; 
}

MEMORY {
  mrom(rx)   : ORIGIN = 0x20000000, LENGTH = 4K
  flash(rx)  : ORIGIN = 0x30000000, LENGTH = 16M
  sram(rwx)  : ORIGIN = 0x0f000000, LENGTH = 8K
  psram(rwx) : ORIGIN = 0x80000000, LENGTH = 4M
}

SECTIONS {

  . = ORIGIN(flash) + _entry_offset;
  .fsbl : {
  . = ALIGN(4);
    KEEP(*(.fsbl))
  } > flash AT > flash : fsbl

  . = ORIGIN(sram);
  .ssbl : {
  . = ALIGN(4);
  _ssbl_vma_start = .;
    KEEP(*(.ssbl))
  . = ALIGN(4);
  _ssbl_vma_end = .;
  } > sram AT > flash : ssbl
  _ssbl_lma_start = LOADADDR(.ssbl);

  . = ALIGN(16);
  _stack_bottom = .;
  . = ORIGIN(sram) + LENGTH(sram);
  _stack_top = .;
  _stack_size = _stack_top - _stack_bottom;
  _stack_pointer = .;

  . = ORIGIN(psram);
  .text : {
  . = ALIGN(4);
  _text_vma_start = .;
    KEEP(*(.text*))
  . = ALIGN(4);
  _text_vma_end = .;
  } > psram AT > flash : text
  _text_lma_start = LOADADDR(.text);
  etext = .;
  _etext = .;

  .rodata : {
  . = ALIGN(4);
  _rodata_vma_start = .;
    KEEP(*(.rodata*))
    *(.srodata*)
  . = ALIGN(4);
  _rodata_vma_end = .;
  } > psram AT > flash : text
  _rodata_lma_start = LOADADDR(.rodata);

  .data : {
  _data_vma_start = .;
    KEEP(*(.data*))
    *(.sdata*)
  . = ALIGN(4);
  _data_vma_end = .;
  } > psram AT > flash : data
  _data_lma_start = LOADADDR(.data);
  edata = .;
  _data = .;

  .bss : {
  . = ALIGN(4);
	_bss_vma_start = .;
    KEEP(*(.bss*))
    *(.sbss*)
    *(.scommon)
  . = ALIGN(4);
  _bss_vma_end = .;
  } > psram : data

  . = ALIGN(4);
  _heap_start = .;
  . = ORIGIN(psram) + LENGTH(psram);
  _heap_end = . ;
  end = .;
  _end = .;

}
