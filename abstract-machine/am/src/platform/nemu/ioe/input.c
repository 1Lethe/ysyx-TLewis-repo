#include <am.h>
#include <nemu.h>

#define KEYDOWN_MASK 0x8000

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  uint32_t key_read = inl(KBD_ADDR);
  kbd->keycode = (uint8_t)key_read;
  if((key_read & KEYDOWN_MASK) >> 15 == 1){
    kbd->keydown = true;
  }else{
    kbd->keydown = false;
  }
}
