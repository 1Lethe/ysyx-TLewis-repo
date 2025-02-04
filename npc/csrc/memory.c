#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>
#include <string.h>
#include "include/memory.h"

extern char *img_file;

static uint8_t pmem[MAX_MEMORY] __attribute((aligned(4096))) = {};

static const uint32_t buildin_img[] = {
    0x00000413, // li s0,0
    0x00009117, // auipc sp,0x9
    0xffc10113, // addi sp,sp,-4 # 80009000
    0x00c000ef, // jal ra,80000018

    0x00000513, // li a0, 0
    0x00008067, // ret

    0xff010113, // addi sp,sp,-16
    0x00000517, // auipc a0,0x0
    0x01c50513, // addi a0,a0,28
    0x00112623, // sw ra,12(sp)
    0xfe9ff0ef, // jal ra,80000010
    0x00050513, // mv a0,a0
    0x00100073, // ebreak
    0x0000006f  // j 80000034
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

long load_img() {
    if(img_file == NULL){
        printf("No image is given.Use the default build-in image.\n");
        memcpy(guest_to_host(RESET_VECTOR), buildin_img, sizeof(buildin_img));
        return 4096;
    }

    FILE *fp = fopen(img_file, "rb");
    assert(fp != NULL);

    fseek(fp, 0, SEEK_END);
    long size = ftell(fp);

    printf("The image is %s, size = %ld.\n", img_file, size);

    fseek(fp, 0, SEEK_SET);
    int ret = fread(guest_to_host(RESET_VECTOR), size, 1, fp);
    assert(ret == 1);

    fclose(fp);
    return size;
}