#include <am.h>
#include <nemu.h>

#define SYNC_ADDR      (VGACTL_ADDR + 4)
#define VMEM_SIZE_ADDR (VGACTL_ADDR + 8)

void __am_gpu_init() {
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  uint32_t config_data = inl(VGACTL_ADDR);
  uint32_t vmem_size = inl(VMEM_SIZE_ADDR);
  int screen_width  = config_data >> 16;
  int screen_height = config_data & 0xFFFF;
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = screen_width,
    .height = screen_height,
    .vmemsz = vmem_size
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  if(ctl->pixels != NULL){
    int screen_width = io_read(AM_GPU_CONFIG).width;
    uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;
    for(int y = 0; y < ctl->h; y++){
      for(int x = 0; x < ctl->w; x++){
        int col_offset = ctl->w * y + x;
        int des_offset = (ctl->y + y) * screen_width + (ctl->x + x);
        uint32_t color = ((uint32_t *)(ctl->pixels))[col_offset];
        fb[des_offset] = color;
      }
    }
  }
  if(ctl->sync){
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
