#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>
#include "memory.h"

uint32_t pmem[1024] = {
    0x01008113,
    0x01008013,
    0x01008093,
    0x01008093
};

uint32_t* guest_to_host(uint32_t paddr) { return pmem + paddr - RESET_VECTOR; }
uint32_t host_to_guest(uint32_t *haddr) { return haddr - pmem + RESET_VECTOR; }

uint32_t pmem_read(uint32_t addr){
    return *(guest_to_host(addr));
}

void mem_out_of_bound(uint32_t addr){
    if(addr < RESET_VECTOR || addr > RESET_VECTOR + MAX_MEMORY){
        printf("pc = 0x%x\n", addr);
        assert(0);
    }
}
