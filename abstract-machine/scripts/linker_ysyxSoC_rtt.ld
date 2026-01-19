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

    __fsymtab_start = .;
    KEEP(*(FSymTab))
    __fsymtab_end = .;
    . = ALIGN(8);
    __vsymtab_start = .;
    KEEP(*(VSymTab))
    __vsymtab_end = .;
    . = ALIGN(8);

    /* section information for initial. */
    . = ALIGN(8);
    __rt_init_start = .;
    KEEP(*(SORT(.rti_fn*)))
    __rt_init_end = .;
    . = ALIGN(8);

    __rt_utest_tc_tab_start = .;
    KEEP(*(UtestTcTab))
    __rt_utest_tc_tab_end = .;

    . = ALIGN(8);
    __am_apps_data_start = .;
    *(__am_apps.data*)
    *(__am_apps.sdata*)
    __am_apps_data_end = .;
    . = ALIGN(8);

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

    . = ALIGN(8);
    _bss_extra_vma_start = .;
    __am_apps_bss_start = .;
    *(__am_apps.bss*)
    *(__am_apps.sbss*)
    *(__am_apps.scommon*)
    _bss_extra_vma_end = .;
    __am_apps_bss_end = .;
    . = ALIGN(8);

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

  /* 我们在链接阶段打开了--orphan-handling=error，这也导致我们必须显式处理所有孤儿段 */
  /* 1. 必须保留的：RISC-V 架构属性 */
  /* 链接器依靠这个来检查对象文件之间的 ABI 兼容性 (如 RVC, Float 等) */
  .riscv.attributes 0 : { *(.riscv.attributes) }

  /* 2. 可以丢弃的：元数据与不需要的段 */
  /DISCARD/ : {
        /* 编译器版本信息，不影响运行 */
        *(.comment)
        
        /* 栈不可执行标记。在裸机中通常手动管理栈，可丢弃，
           或者显式映射。这里为了消除报错，丢弃通常是安全的。 */
        *(.note*)
        *(.note.GNU-stack)

        /* 3. 重点：重定位信息 (.rela.*) */
        /* 你的报错包含大量 .rela.fsbl.entry, .rela.sdata.heap 等。
           在生成最终的静态可执行文件（Static Executable）时，
           这些重定位段通常已经完成了历史使命，或者是多余的。
           除非你需要保留重定位信息供 Bootloader 动态加载，否则可以直接丢弃。 */
        *(.rela*)
        *(.rel*)
    }
}
