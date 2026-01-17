.section .fsbl, "ax"
.globl _start
.type _start, @function


_start:
    # 1. 基础环境初始化
    mv s0, zero                 # 初始化帧指针 (s0/fp = x8, RV32E可用)
    la sp, _stack_pointer       # 初始化栈指针 (sp = x2, RV32E可用)
    # 2. 准备搬运 SSBL (Flash -> SRAM)
    # 从链接脚本中获取符号地址
    la a0, _ssbl_lma_start      # 源地址：Flash 中的起始位置 (LMA)
    la a1, _ssbl_vma_start      # 目的地址：SRAM 中的起始位置 (VMA)
    la a2, _ssbl_vma_end        # 结束边界：SRAM 中的结束位置
    # 3. 执行搬运循环
copy_ssbl_loop:
    lb a3, 0(a0)                # Load Word: 从 Flash 读取指令/数据
    sb a3, 0(a1)                # Store Word: 写入 SRAM
    addi a0, a0, 1              # 源指针后移 4 字节
    addi a1, a1, 1              # 目的指针后移 4 字节
    bltu a1, a2, copy_ssbl_loop

copy_ssbl_done:
    la t0, _ssbl_vma_start  
    jr t0

