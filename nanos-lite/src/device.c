#include <common.h>
#include "device.h"

#if defined(MULTIPROGRAM) && !defined(TIME_SHARING)
# define MULTIPROGRAM_YIELD() yield()
#else
# define MULTIPROGRAM_YIELD()
#endif

#define NAME(key) \
  [AM_KEY_##key] = #key,

static const char *keyname[256] __attribute__((used)) = {
  [AM_KEY_NONE] = "NONE",
  AM_KEYS(NAME)
};

size_t serial_write(const void *buf, size_t offset, size_t len) {
  size_t charput_num = 0;
  char *char_buf_ptr = (char *)(intptr_t)buf;

  for(int i = 0; i < len; i++){
    putch(*char_buf_ptr++);
    charput_num++;
  }

  return charput_num;
}

int timer_gettimeofday(struct timeval *tv, struct timezone *tz) {
  // we use RTC in AM as system time 
  long us = io_read(AM_TIMER_UPTIME).us;

  /* The use of the timezone structure is obsolete; 
  the tz argument should normally  be  specified  as NULL. see gettimeofday(2) */
  assert(tv != NULL);
  assert(tz == NULL);

  tv->tv_sec = us / 1000000;
  tv->tv_usec = us % 1000000;

  return 0;
}

size_t events_read(void *buf, size_t offset, size_t len) {
  return 0;
}

size_t dispinfo_read(void *buf, size_t offset, size_t len) {
  return 0;
}

size_t fb_write(const void *buf, size_t offset, size_t len) {
  return 0;
}

void init_device() {
  Log("Initializing devices...");
  ioe_init();
}
