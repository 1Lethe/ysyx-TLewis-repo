#ifndef __MEMORY_H
#define __MEMORY_H

#include <stdlib.h>
#include <assert.h>
#include <stdint.h>

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
uint32_t host_read(void *addr, int len);
void host_write(void *addr, int len, uint32_t data);
void pmem_write(uint32_t addr, int len, uint32_t data);
uint32_t pmem_read(uint32_t addr, uint32_t len);
bool mem_out_of_bound(uint32_t addr);
void cpy_buildin_img(void);

#endif