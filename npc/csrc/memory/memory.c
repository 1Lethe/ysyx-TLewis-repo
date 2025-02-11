#include "memory.h"
#include "debug.h"

extern char *img_file;

static uint8_t pmem[MEMORY_SIZE] __attribute((aligned(4096))) = {};

static const uint32_t buildin_img[] = {
    0x00000297,  // auipc t0,0

    0x0202ac23,  // sw  zero,56(t0)
    0x02029823,  // sh zero, 48(t0)
    0x02029a23,  // sb zero, 52(t0)

    0x0102c503,  // lbu a0,24(t0)
    0x03028a03,  //  lb  x20 48(t0)
    0x02c2ca83,  //  lbu x21 44(t0)
    0x02c29b03,  //  lh  x22 44(t0)
    0x02c2db83,  //  lhu x23 44(t0)
    0x02c2ac03,  //  lw  x24 44(t0)

    0x00100073,  // ebreak (used as npc_trap)
    0xdeadbeef,  // some data
    0xabcdabcd,
    0xaaaaaaaa,
    0xbbbbbbbb,
    0xcccccccc
};

// TODO: expand word_t paddr_t ...

uint8_t* guest_to_host(uint32_t paddr) { return pmem + paddr - RESET_VECTOR; }
uint32_t host_to_guest(uint8_t *haddr) { return haddr - pmem + RESET_VECTOR; }

static uint32_t host_read(void *addr, int len){
    switch(len){
        case 1: return *(uint8_t *)addr;
        case 2: return *(uint16_t *)addr;
        case 4: return *(uint32_t *)addr;
        default : Assert(0, "not support");
    }
}

static void host_write(void *addr, int len, uint32_t data) {
    switch(len){
        case 1: *(uint8_t *)addr = (uint8_t)data; break;
        case 2: *(uint16_t *)addr = (uint16_t)data; break;
        case 4: *(uint32_t *)addr = data; break;
        default: Assert(0, "not support");
    }
}

void pmem_write(uint32_t addr, int len, uint32_t data) {
    Assert(!mem_out_of_bound(addr), "Invalid pmem addr.ABORT");
    /* convert addr and fetch instruction */
    host_write(guest_to_host(addr), len, data);
}

uint32_t pmem_read(uint32_t addr,uint32_t len){
    //printf("PMEM read addr 0x%x ", addr);
    Assert(!mem_out_of_bound(addr), "Invalid pmem addr.ABORT");
    uint32_t ret = host_read(guest_to_host(addr), len);
    //printf("value 0x%08x\n", ret);
    return ret;
}

void cpy_buildin_img(void){
    memcpy(guest_to_host(MEMORY_BASE), buildin_img, sizeof(buildin_img));
}

bool mem_out_of_bound(uint32_t addr){
    if(addr < MEMORY_BASE || addr > MEMORY_BASE + MEMORY_SIZE){
        return true;
    }else{
        return false;
    }
}

/* Sim module use DPI_C */
extern "C" int sim_pmem_read(int raddr) {
    // 总是读取地址为`raddr & ~0x3u`的4字节返回
    return pmem_read(raddr & ~0x3u, 4);
}

extern "C" void sim_pmem_write(int waddr, int wdata, char wmask) {
    // 总是往地址为`waddr & ~0x3u`的4字节按写掩码`wmask`写入`wdata`
    // `wmask`中每比特表示`wdata`中1个字节的掩码,
    // 如`wmask = 0x3`代表只写入最低2个字节, 内存中的其它字节保持不变
    int addr_al = waddr & ~0x3u;
    int wr_time = 0;;
    for(int i = 0;i < 4; i++){
        if(wmask >> i & 0x01){
            uint8_t wbyte = (wdata >> (wr_time * 8)) & 0xFF;
            wr_time++;
            //printf("PMEM write addr 0x%x value 0x%x\n", addr_al + i, wbyte);                
            pmem_write(addr_al + i, 1, wbyte);
        }
    }
}
