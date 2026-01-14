#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

#define PRINT_BUF_SIZE 128 
#define MAX_PRINT      128

// .bss段
static char g_printf_buf[PRINT_BUF_SIZE];

// 辅助函数：根据进制转换字符
static inline char to_hex(int v) {
    return (v < 10) ? (v + '0') : (v - 10 + 'a');
}

int vsnprintf(char *out, size_t size, const char *fmt, va_list ap) {
    size_t generated_len = 0; // 记录理论长度
    char *buf_ptr = out;      // 当前写入位置
    
    // 只有当 size > 0 且 out 有效时，我们才真正写入
    // end 指向最后一个允许写入字符的位置（留给 \0）
    char *end = (size > 0 && out) ? (out + size - 1) : NULL;

    // 宏：负责“写入字符”和“统计长度”
    // 如果还没满，就写；无论满没满，长度计数器都加 1
    #define EMIT(c) do { \
        if (buf_ptr < end) { *buf_ptr++ = (c); } \
        generated_len++; \
    } while (0)

    while (*fmt) {
        if (*fmt != '%') {
            EMIT(*fmt++);
            continue;
        }

        fmt++; // skip '%'
        
        // 处理 %%
        if (*fmt == '%') {
            EMIT('%');
            fmt++;
            continue;
        }

        switch (*fmt++) {
            case 's': {
                char *s = va_arg(ap, char *);
                if (!s) s = "(null)";
                while (*s) {
                    EMIT(*s++); // 逐字符处理，保证计数正确
                }
                break;
            }
            case 'c': {
                // char 在变参中会被提升为 int
                int c = va_arg(ap, int);
                EMIT((char)c);
                break;
            }
            case 'd': 
            case 'x': 
            case 'p': {
                unsigned long num;
                int base = 10;
                char type = *(fmt - 1);
                // 处理类型
                if (type == 'd') {
                    long val = va_arg(ap, int); // int 提升为 long (RV64/x64适配)
                    if (val < 0) {
                        EMIT('-');
                        num = (unsigned long)(-val);
                    } else {
                        num = (unsigned long)val;
                    }
                } else if (type == 'p') {
                    // 适配 64 位指针
                    num = (unsigned long)va_arg(ap, void *); 
                    base = 16;
                } else { // 'x'
                    // 适配 64 位场景下的 hex 打印
                    num = va_arg(ap, unsigned int); 
                    base = 16;
                }

                // 数字转字符串
                // 64位整数最大约 20 字节，预留 24 字节足够安全
                char num_buf[24]; 
                int i = 0;
                
                if (num == 0) {
                    num_buf[i++] = '0';
                } else {
                    while (num != 0) {
                        num_buf[i++] = to_hex(num % base);
                        num /= base;
                    }
                }

                while (i > 0) {
                    EMIT(num_buf[--i]);
                }
                break;
            }
            default:
                // 遇到不支持的格式符，原样打印（例如 %z）
                EMIT('%');
                EMIT(*(fmt-1));
                break;
        }
    }

    // 最终封口：只要 buffer 存在且 size > 0，就必须以 \0 结尾
    if (size > 0 && out) {
        if (buf_ptr < out + size) {
            *buf_ptr = '\0';
        } else {
            out[size - 1] = '\0';
        }
    }

    return generated_len;
}
#undef EMIT

int printf(const char *fmt, ...) {
    va_list ap;
    int len;

    va_start(ap, fmt);
    len = vsnprintf(g_printf_buf, PRINT_BUF_SIZE, fmt, ap);
    va_end(ap);

    for (int i = 0; i < len; i++) {
        putch(g_printf_buf[i]);
    }

    return len;
}

int sprintf(char *out, const char *fmt, ...) {
    va_list ap;
    int len = 0;

    va_start(ap, fmt);
    len = vsnprintf(out, (size_t)(MAX_PRINT), fmt, ap);
    va_end(ap);

    return len;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
    va_list ap;
    int len = 0;

    va_start(ap, fmt);
    len = vsnprintf(out, n, fmt, ap);
    va_end(ap);

    return len;

}

int vsprintf(char *out, const char *fmt, va_list ap) {
    return vsnprintf(out, (size_t)(MAX_PRINT), fmt, ap);
}

#endif
