#ifndef __DEVICE_H__
#define __DEVICE_H__

typedef long time_t;
typedef long suseconds_t;

struct timeval {
  time_t tv_sec;       /* seconds */
  suseconds_t tv_usec;  /* microseconds */
};

struct timezone {
  int tz_minuteswest;  /* minutes west of Greenwich */
  int tz_dsttime;      /* type of DST correction */
};

size_t serial_write(const void *buf, size_t offset, size_t len);
size_t events_read(void *buf, size_t offset, size_t len);
int timer_gettimeofday(struct timeval *tv, struct timezone *tz);

#endif