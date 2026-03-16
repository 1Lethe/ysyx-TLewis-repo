#include <am.h>
#include <amdev.h>
#include <ysyxSoC.h>
#include <scancode.h>

static uint32_t keymap[256] = {};

#define AM_KEYMAP(k) keymap[AM_SCANCODE_ ## k] = AM_KEY_ ## k;

static uint32_t scancode_2_amcode(uint8_t scancode) {
  return keymap[scancode];
}

void __am_keymap_init(void) {
  MAP(AM_KEYS, AM_KEYMAP);
}

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  uint8_t key_scancode = inb(PS2_CTRL_PORT);
  if(key_scancode == 0xF0) {
    key_scancode = inb(PS2_CTRL_PORT);
    kbd->keycode = scancode_2_amcode(key_scancode);
    kbd->keydown = false;
  }else {
    kbd->keycode = scancode_2_amcode(key_scancode);
    kbd->keydown = true;
  }
}