#include <am.h>
#include <nemu.h>

#include <klib.h>

#define AUDIO_FREQ_ADDR       (AUDIO_ADDR + 0x00)
#define AUDIO_CHANNELS_ADDR   (AUDIO_ADDR + 0x04)
#define AUDIO_SAMPLES_ADDR    (AUDIO_ADDR + 0x08)
#define AUDIO_SBUF_SIZE_ADDR  (AUDIO_ADDR + 0x0c)
#define AUDIO_INIT_ADDR       (AUDIO_ADDR + 0x10)
#define AUDIO_COUNT_ADDR      (AUDIO_ADDR + 0x14)
#define AUDIO_READCONFIG_ADDR (AUDIO_ADDR + 0x18)

static uint32_t sbuf_windex = 0;
static uint32_t audio_bufsize = 0;

void __am_audio_init() {
}

void __am_audio_config(AM_AUDIO_CONFIG_T *cfg) {
  outl(AUDIO_READCONFIG_ADDR, 1);
  audio_bufsize = inl(AUDIO_SBUF_SIZE_ADDR);
  *cfg = (AM_AUDIO_CONFIG_T) {
    .present = true,
    .bufsize = audio_bufsize
  };
}

void __am_audio_ctrl(AM_AUDIO_CTRL_T *ctrl) {
  outl(AUDIO_FREQ_ADDR, ctrl->freq);
  outl(AUDIO_CHANNELS_ADDR, ctrl->channels);
  outl(AUDIO_SAMPLES_ADDR, ctrl->samples);
  outl(AUDIO_INIT_ADDR, 1); // set finish audio init flag
  inl(AUDIO_SBUF_SIZE_ADDR); // call callback function in NEMU
}

void __am_audio_status(AM_AUDIO_STATUS_T *stat) {
  stat->count = inl(AUDIO_COUNT_ADDR);
}

void __am_audio_play(AM_AUDIO_PLAY_T *ctl) {
  uint8_t *sbuf_start = (uint8_t *)ctl->buf.start;
  uint8_t *sbuf_end = (uint8_t *)ctl->buf.end;
  uint8_t *sbuf_ptr = sbuf_start;
  int count = 0;

  outl(AUDIO_READCONFIG_ADDR, 1);
  int count_prev = inl(AUDIO_COUNT_ADDR);

  while(sbuf_ptr < sbuf_end){
    sbuf_windex = (sbuf_windex + 1) % audio_bufsize;
    outb((uintptr_t)(AUDIO_SBUF_ADDR + sbuf_windex), *(sbuf_ptr++));
    count++;
  }

  outl(AUDIO_COUNT_ADDR, count_prev + count);
}
