#ifndef __MEMORY_H
#define __MEMORY_H

#include <stdlib.h>
#include <assert.h>
#include <stdint.h>

#ifndef USE_SOC
// NOTE: Must same as REF in difftest
#define MEMORY_SIZE   0x8000000
#define MEMORY_BASE  0x80000000
#define RESET_VECTOR 0x80000000

#define PMEM_LEFT MEMORY_BASE
#define PMEM_RIGHT (MEMORY_BASE + MEMORY_SIZE - 1)

static inline bool in_pmem(uint32_t addr) {
  return addr - MEMORY_BASE < MEMORY_SIZE;
}


uint8_t* guest_to_host(uint32_t paddr);
uint32_t host_to_guest(uint8_t *haddr);
void pmem_write(uint32_t addr, int len, uint32_t data);
uint32_t pmem_read(uint32_t addr, uint32_t len);
void cpy_buildin_img(void);
void init_mem(void);

#else /* USE_SOC */

#define MROM_SIZE   0x00000fff
#define MROM_BASE   0x20000000

static inline bool guest_in_mrom(uint32_t addr) {
  return (addr >= MROM_BASE) && (addr < MROM_SIZE + MROM_BASE);
}

static inline bool host_in_mrom(uint32_t addr) {
  return  (addr >= 0x0) && (addr < MROM_SIZE);
}

void init_mrom(void);
uint8_t* wr_mrom_addr(uint32_t addr);
uint8_t* rd_mrom_addr(uint32_t addr);
#endif

uint32_t host_read(void *addr, int len);
void host_write(void *addr, int len, uint32_t data);
bool mem_out_of_bound(uint32_t addr);

#endif