#ifndef __MEMORY_H
#define __MEMORY_H

#include <stdint.h>

#define MAX_MEMORY 0x8000
#define RESET_VECTOR 0x80000000

uint32_t* guest_to_host(uint32_t paddr);
uint32_t host_to_guest(uint32_t *haddr);
uint32_t pmem_read(uint32_t addr);
void mem_out_of_bound(uint32_t addr);

#endif