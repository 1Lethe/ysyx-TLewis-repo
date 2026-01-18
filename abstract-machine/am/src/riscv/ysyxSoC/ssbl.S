.section .ssbl.entry, "ax"
.globl _ssbl_main
.type _ssbl_main, @function

_ssbl_main:
    la a0, _text_lma_start      # 源地址 (LMA)
    la a1, _text_vma_start      # 目的地址 (VMA)
    la a2, _text_vma_end        # 结束地址
    bgeu a1, a2, copy_text_end  # 检查空段
copy_text_loop:
    lb a3, 0(a0)
    sb a3, 0(a1)
    addi a0, a0, 1
    addi a1, a1, 1
    bltu a1, a2, copy_text_loop
copy_text_end:

    la a0, _rodata_lma_start    # 源地址 (LMA)
    la a1, _rodata_vma_start    # 目的地址 (VMA)
    la a2, _rodata_vma_end      # 结束地址
    bgeu a1, a2, copy_rodata_end
copy_rodata_loop:
    lb a3, 0(a0)
    sb a3, 0(a1)
    addi a0, a0, 1
    addi a1, a1, 1
    bltu a1, a2, copy_rodata_loop
copy_rodata_end:

    # 2. 搬运 .data 段 (LMA -> VMA)
    la a0, _data_lma_start      # a0 = 源地址 (src)
    la a1, _data_vma_start      # a1 = 目的地址 (dst)
    la a2, _data_vma_end        # a2 = 结束地址 (end)
    # 检查是否需要搬运 (防止空段导致错误)
    bgeu a1, a2, copy_data_end  # 如果 dst >= end，直接跳过
copy_data_loop:
    lb a3, 0(a0)                # 从 src 加载一个字节到 a3
    sb a3, 0(a1)                # 将 a3 存储到 dst
    addi a0, a0, 1              # src++
    addi a1, a1, 1              # dst++
    bltu a1, a2, copy_data_loop # 如果 dst < end，继续循环

copy_data_end:
    # 3. 清零 .bss 段
    la a1, _bss_vma_start       # a1 = 目的地址 (dst)
    la a2, _bss_vma_end         # a2 = 结束地址 (end)
    bgeu a1, a2, clear_bss_end  # 如果 dst >= end，直接跳过
clear_bss_loop:
    sb zero, 0(a1)              # 写入 0 (利用 zero 寄存器)
    addi a1, a1, 1              # dst++
    bltu a1, a2, clear_bss_loop # 如果 dst < end，继续循环
clear_bss_end:
    # 4. 跳转到 C 运行时环境
    call _trm_init