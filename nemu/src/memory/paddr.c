/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <memory/host.h>
#include <memory/paddr.h>
#include <device/mmio.h>
#include <isa.h>

/*  NOTE: 为ysyxSoC的difftest情况，使用NEMU作为REF的访存机制解释
 *  在使用NEMU作为NPC在ysyxSoC环境下difftest的REF时，由于NPC的访存地址并不一定 > 0x80000000 （链接脚本确定）
 *  我们将NEMU的内存基地址CONFIG_MBASE = 0x0，CONFIG_MSIZE = 0xc0000000 （与ysyxSoC的内存映射位置有关，可能需更大）
 *  还需要将PC_OFFSET = 0x20000000 (MROM偏移地址，后续可能还需修改)
 *  并启用E拓展
 *  对于近3GB的寻址空间，我们为了让NEMU内存分配合理：
 *  必须打开NEMU menuconfig中的"使用 malloc 分配内存",将内存分配在堆区，否则会链接失败（.bss过长 > 2GB）
 *  此外还要关闭"使用随机数初始化内存"，在不使用随机数初始化时，借助计算机的虚拟内存映射机制，
 *  应用程序并没有被完整分配3GB内存，而是按需分配（详见PA4.2）。如果使用随机数初始化内存，那么应用程序会被完整分配3GB，
 *  这是我们不希望的。你可以使用htop或free -h观测Mem和Swap是否超标。
 * 
 *  在NEMU中，PC被初始化为RESET_VECTOR -> (PMEM_LEFT + CONFIG_PC_RESET_OFFSET) <isa>/init.c中
 *  PMEM_LEFT -> PMEM_LEFT  ((paddr_t)CONFIG_MBASE) = 0x0，即在DUT中我们需要将目标程序复制到NEMU中的0x0位置。
 * 
 *  NOTE: 在native环境下，正确设置 CONFIG_MBASE = 0x80000000; CONFIG_MSIZE = 0x8000000; PC_OFFSET = 0x0;
 *  “using garray”; "using random".
 */

#if   defined(CONFIG_PMEM_MALLOC)
static uint8_t *pmem = NULL;
#else // CONFIG_PMEM_GARRAY
static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
#endif

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  IFDEF(CONFIG_MTRACE, printf("MTRACE read  addr: 0x%8x, data: 0x%08x\n", addr, ret));
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  /* convert addr and fetch instruction */
  host_write(guest_to_host(addr), len, data);
  IFDEF(CONFIG_MTRACE, printf("MTRACE write addr: 0x%08x, data: 0x%08x\n", addr, data));
}

static void out_of_bound(paddr_t addr) {
  panic("address = " FMT_PADDR " is out of bound of pmem [" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, cpu.pc);
}

void init_mem() {
#if   defined(CONFIG_PMEM_MALLOC)
  pmem = malloc(CONFIG_MSIZE);
  assert(pmem);
#endif
  IFDEF(CONFIG_MEM_RANDOM, memset(pmem, rand(), CONFIG_MSIZE));
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
}

word_t paddr_read(paddr_t addr, int len) {
  if (likely(in_pmem(addr))) {
    word_t ret = pmem_read(addr, len);
    return ret;
  }
  IFDEF(CONFIG_DEVICE, return mmio_read(addr, len));
  out_of_bound(addr);
  return 0;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  if (likely(in_pmem(addr))) { 
    pmem_write(addr, len, data);
    IFDEF(CONFIG_DIFFTEST, diff_set_REF_memtrace_struct(data, addr, len)); 
    return; 
  }
#ifdef CONFIG_DEVICE
  mmio_write(addr, len, data);
  IFDEF(CONFIG_DIFFTEST, diff_set_REF_memtrace_struct(data, addr, len));
  return; 
#endif
  out_of_bound(addr);
}
