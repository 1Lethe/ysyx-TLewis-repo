#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>
#include <assert.h>
#include <fcntl.h>

static int evtdev = -1;
static int fbdev = -1;
static int screen_w = 0, screen_h = 0;
static int canvas_x = 0, canvas_y = 0;
static int canvas_w = 0, canvas_h = 0;

uint32_t NDL_GetTicks() {
  struct timeval tv;
  int ret = gettimeofday(&tv, NULL);
  assert(ret == 0);

  return (tv.tv_sec * 1000 + tv.tv_usec / 1000);
}

int NDL_PollEvent(char *buf, int len) {
  int ev_fd = open("/dev/events", 0, 0);

  int is_key = read(ev_fd, buf, len * sizeof(char));

  close(ev_fd);

  return is_key;
}

void NDL_OpenCanvas(int *w, int *h) {
  assert(w != NULL);
  assert(h != NULL);

  if (getenv("NWM_APP")) {
    int fbctl = 4;
    fbdev = 5;
    screen_w = *w; screen_h = *h;
    char buf[64];
    int len = sprintf(buf, "%d %d", screen_w, screen_h);
    // let NWM resize the window and create the frame buffer
    write(fbctl, buf, len);
    while (1) {
      // 3 = evtdev
      int nread = read(3, buf, sizeof(buf) - 1);
      if (nread <= 0) continue;
      buf[nread] = '\0';
      if (strcmp(buf, "mmap ok") == 0) break;
    }
    close(fbctl);
  }

  // parse the width and height of screen
  char dispinfo_buff[64];
  int dispinfo_fd = open("/proc/dispinfo", 0, 0);
  read(dispinfo_fd, dispinfo_buff, sizeof(dispinfo_buff));
  sscanf(dispinfo_buff, "WIDTH:%d\nHEIGHT:%d\n", &screen_w, &screen_h);
  close(dispinfo_fd);
  if(*w == 0 && *h == 0){
    canvas_w = screen_w; canvas_h = screen_h;
  }else{
    canvas_w = *w; canvas_h = *h;
  }

  // make the canvas in the center
  canvas_x = screen_w / 2 - canvas_w / 2;
  canvas_y = screen_h / 2 - canvas_h / 2;
}

void NDL_DrawRect(uint32_t *pixels, int x, int y, int w, int h) {
  assert(pixels != NULL);

  int fb_fd = open("/dev/fb", 0, 0);

  for(int i = 0; i < h && i + y < canvas_h; i++){
    // pixel is measured by 0x00RRGGBB (4 bytes) , we need translate offset and w to 4 bytes (* 4)
    int offset = 4 * ((canvas_y + y + i) * screen_w + (canvas_x + x));
    lseek(fb_fd, offset, SEEK_SET);
    w = canvas_w - x > w ? canvas_w - x : w;
    write(fb_fd, pixels + w * i, 4 * w);
  }

  close(fb_fd);
}

void NDL_OpenAudio(int freq, int channels, int samples) {
}

void NDL_CloseAudio() {
}

int NDL_PlayAudio(void *buf, int len) {
  return 0;
}

int NDL_QueryAudio() {
  return 0;
}

int NDL_Init(uint32_t flags) {
  if (getenv("NWM_APP")) {
    evtdev = 3;
  }
  return 0;
}

void NDL_Quit() {
}
