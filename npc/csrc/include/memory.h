#ifndef __MEMORY_H
#define __MEMORY_H

<<<<<<< HEAD
#include <stdint.h>

#define MAX_MEMORY 0xFFFFFFF
=======
#include <stdlib.h>
#include <assert.h>

#define MEMORY_SIZE   0x8000000
#define MEMORY_BASE  0x80000000
>>>>>>> npc
#define RESET_VECTOR 0x80000000

uint8_t* guest_to_host(uint32_t paddr);
uint32_t host_to_guest(uint8_t *haddr);
<<<<<<< HEAD
uint32_t host_read(void *addr, int len);
uint32_t pmem_read(uint32_t addr, uint32_t len);
void mem_out_of_bound(uint32_t addr);
long load_img(void);
=======
void pmem_write(uint32_t addr, int len, uint32_t data);
uint32_t pmem_read(uint32_t addr, uint32_t len);
bool mem_out_of_bound(uint32_t addr);
void cpy_buildin_img(void);
>>>>>>> npc

#endif