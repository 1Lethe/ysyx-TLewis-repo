#ifndef __MEMORY_H__
#define __MEMORY_H__

#include <stdint.h>

#define RESET_VECTOR 0x80000000

uint32_t pmem[] = {
    0x12345678,
};

uint32_t* guest_to_host(uint32_t paddr);
uint32_t host_to_guest(uint32_t *haddr);
uint32_t pmem_read(uint32_t addr);

#include "memory.c"

#endif