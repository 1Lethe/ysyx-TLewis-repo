#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "memory.h"

uint32_t pmem[0x800] = {
    0x12345678,
    0x12312312,
};

uint32_t* guest_to_host(uint32_t paddr) { return pmem + paddr - RESET_VECTOR; }
uint32_t host_to_guest(uint32_t *haddr) { return haddr - pmem + RESET_VECTOR; }

uint32_t pmem_read(uint32_t addr){
    return *(guest_to_host(addr));
}
