#include "../include/memory.h"

extern char *img_file;

static uint8_t pmem[MAX_MEMORY] __attribute((aligned(4096))) = {};

const uint32_t buildin_img[] = {
    0x00000297,  // auipc t0,0
    0x00028823,  // sb  zero,16(t0)
    0x0102c503,  // lbu a0,16(t0)
    0x00100073,  // ebreak (used as npc_trap)
    0xdeadbeef,  // some data
};

// TODO: expand word_t paddr_t ...

uint8_t* guest_to_host(uint32_t paddr) { return pmem + paddr - RESET_VECTOR; }
uint32_t host_to_guest(uint8_t *haddr) { return haddr - pmem + RESET_VECTOR; }

uint32_t host_read(void *addr, int len){
    switch(len){
        case 4: return *(uint32_t *)addr;
        default : assert(0);
    }
}

uint32_t pmem_read(uint32_t addr,uint32_t len){
    mem_out_of_bound(addr);
    uint32_t ret = host_read(guest_to_host(addr), len);
    return ret;
}

void mem_out_of_bound(uint32_t addr){
    if(addr < RESET_VECTOR || addr > RESET_VECTOR + MAX_MEMORY){
        printf("pc = 0x%x\n", addr);
        assert(0);
    }
}
