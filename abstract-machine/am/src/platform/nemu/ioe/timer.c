#include <am.h>
#include <nemu.h>

void __am_timer_init() {
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uint32_t time_low = 0;
  uint32_t time_high = 0;
  uint64_t time = 0;

  time_high = inl(RTC_ADDR + 4);
  time_low = inl(RTC_ADDR);
  time = time_low | ((uint64_t)time_high << 32);
  uptime->us = time;
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}
