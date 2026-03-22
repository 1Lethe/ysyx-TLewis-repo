#include <am.h>
#include <ysyxSoC.h>

#include <klib.h>

void __am_gpu_init() {
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = VGA_SCREEN_WIDTH,
    .height = VGA_SCREEN_HEIGHT,
    .vmemsz = VGA_SCREEN_VMEM_SIZE
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  if(ctl->pixels != NULL){
    uint32_t *fb = (uint32_t *)(uintptr_t)VGA_FBUF_ADDR;
    for(int y = 0; y < ctl->h; y++){
      for(int x = 0; x < ctl->w; x++){
        int col_offset = ctl->w * y + x;
        int des_offset = (ctl->y + y) * VGA_SCREEN_WIDTH + (ctl->x + x);
        uint32_t color = ((uint32_t *)(ctl->pixels))[col_offset];
        fb[des_offset] = color;
      }
    }
  }
  if(ctl->sync){
    outl(VGA_SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
