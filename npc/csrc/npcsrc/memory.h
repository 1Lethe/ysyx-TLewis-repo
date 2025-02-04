#ifndef __MEMORY_H
#define __MEMORY_H

#include <stdint.h>

#define MAX_MEMORY 0xFFFFFFF
#define RESET_VECTOR 0x80000000

uint8_t* guest_to_host(uint32_t paddr);
uint32_t host_to_guest(uint8_t *haddr);
uint32_t host_read(void *addr, int len);
uint32_t pmem_read(uint32_t addr);
void mem_out_of_bound(uint32_t addr);
long load_img(void);

#endif