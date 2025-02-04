#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>
#include <string.h>
#include "memory.h"

extern char *img_file;

uint8_t pmem[MAX_MEMORY] __attribute((aligned(4096))) = {};

static const uint32_t buildin_img[] = {
    0x000400b7, // lui x1,64 (64,0)
    0x01008113, // addi x2,x1,16 (64,80)
    0x000ff197, // auipc x3,255
    0x00100073, // ebreak
}

uint8_t* guest_to_host(uint32_t paddr) { return pmem + paddr - RESET_VECTOR; }
uint32_t host_to_guest(uint8_t *haddr) { return haddr - pmem + RESET_VECTOR; }

uint32_t pmem_read(uint32_t addr){
    return *(guest_to_host(addr + 1));
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