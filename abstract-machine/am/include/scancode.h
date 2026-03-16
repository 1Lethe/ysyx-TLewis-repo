#ifndef KEYCODE_H__
#define KEYCODE_H__

typedef enum {
    // 第一行：功能键区
    AM_SCANCODE_ESCAPE       = 0x76,
    AM_SCANCODE_F1           = 0x05,
    AM_SCANCODE_F2           = 0x06,
    AM_SCANCODE_F3           = 0x04,
    AM_SCANCODE_F4           = 0x0C,
    AM_SCANCODE_F5           = 0x03,
    AM_SCANCODE_F6           = 0x0B,
    AM_SCANCODE_F7           = 0x83,
    AM_SCANCODE_F8           = 0x0A,
    AM_SCANCODE_F9           = 0x01,
    AM_SCANCODE_F10          = 0x09,
    AM_SCANCODE_F11          = 0x78,
    AM_SCANCODE_F12          = 0x07,

    // 第二行：数字与符号
    AM_SCANCODE_GRAVE        = 0x0E,  // ` / ~ 键
    AM_SCANCODE_1            = 0x16,
    AM_SCANCODE_2            = 0x1E,
    AM_SCANCODE_3            = 0x26,
    AM_SCANCODE_4            = 0x25,
    AM_SCANCODE_5            = 0x2E,
    AM_SCANCODE_6            = 0x36,
    AM_SCANCODE_7            = 0x3D,
    AM_SCANCODE_8            = 0x3E,
    AM_SCANCODE_9            = 0x46,
    AM_SCANCODE_0            = 0x45,
    AM_SCANCODE_MINUS        = 0x4E,  // - / _ 键
    AM_SCANCODE_EQUALS       = 0x55,  // = / + 键
    AM_SCANCODE_BACKSPACE    = 0x66,

    // 第三行：字母 Q-P 与括号
    AM_SCANCODE_TAB          = 0x0D,
    AM_SCANCODE_Q            = 0x15,
    AM_SCANCODE_W            = 0x1D,
    AM_SCANCODE_E            = 0x24,
    AM_SCANCODE_R            = 0x2D,
    AM_SCANCODE_T            = 0x2C,
    AM_SCANCODE_Y            = 0x35,
    AM_SCANCODE_U            = 0x3C,
    AM_SCANCODE_I            = 0x43,
    AM_SCANCODE_O            = 0x44,
    AM_SCANCODE_P            = 0x4D,
    AM_SCANCODE_LEFTBRACKET  = 0x54,  // [ / { 键
    AM_SCANCODE_RIGHTBRACKET = 0x5B,  // ] / } 键
    AM_SCANCODE_BACKSLASH    = 0x5D,  // \ / | 键

    // 第四行：字母 A-L 与符号
    AM_SCANCODE_CAPSLOCK     = 0x58,
    AM_SCANCODE_A            = 0x1C,
    AM_SCANCODE_S            = 0x1B,
    AM_SCANCODE_D            = 0x23,
    AM_SCANCODE_F            = 0x2B,
    AM_SCANCODE_G            = 0x34,
    AM_SCANCODE_H            = 0x33,
    AM_SCANCODE_J            = 0x3B,
    AM_SCANCODE_K            = 0x42,
    AM_SCANCODE_L            = 0x4B,
    AM_SCANCODE_SEMICOLON    = 0x4C,  // ; / : 键
    AM_SCANCODE_APOSTROPHE   = 0x52,  // ' / " 键
    AM_SCANCODE_RETURN       = 0x5A,  // Enter 键

    // 第五行：字母 Z-M 与符号
    AM_SCANCODE_LSHIFT       = 0x12,
    AM_SCANCODE_Z            = 0x1A,
    AM_SCANCODE_X            = 0x22,
    AM_SCANCODE_C            = 0x21,
    AM_SCANCODE_V            = 0x2A,
    AM_SCANCODE_B            = 0x32,
    AM_SCANCODE_N            = 0x31,
    AM_SCANCODE_M            = 0x3A,
    AM_SCANCODE_COMMA        = 0x41,  // , / < 键
    AM_SCANCODE_PERIOD       = 0x49,  // . / > 键
    AM_SCANCODE_SLASH        = 0x4A,  // / / ? 键
    AM_SCANCODE_RSHIFT       = 0x59,

    // 第六行：底部控制键
    AM_SCANCODE_LCTRL        = 0x14,
    AM_SCANCODE_LALT         = 0x11,
    AM_SCANCODE_SPACE        = 0x29,

    // 扩展区：方向键与导航键
    // NOTE: 均有0xE0前缀
    AM_SCANCODE_APPLICATION  = 0x2F, 
    AM_SCANCODE_UP           = 0x75,
    AM_SCANCODE_DOWN         = 0x72,
    AM_SCANCODE_LEFT         = 0x6B,
    AM_SCANCODE_RIGHT        = 0x74,
    AM_SCANCODE_INSERT       = 0x70,
    AM_SCANCODE_DELETE       = 0x71,
    AM_SCANCODE_HOME         = 0x6C,
    AM_SCANCODE_END          = 0x69,
    AM_SCANCODE_PAGEUP       = 0x7D,
    AM_SCANCODE_PAGEDOWN     = 0x7A,
    AM_SCANCODE_RALT         = 0x11,
    AM_SCANCODE_RCTRL        = 0x14
} am_scancode_t;

#endif