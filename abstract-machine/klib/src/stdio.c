#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

#define PUTCHAR_BUF_SIZE 5000

int printf(const char *fmt, ...) {
  char putchar_buf[PUTCHAR_BUF_SIZE];
  va_list ap;
  size_t len = 0;

  memset(putchar_buf, '\0', PUTCHAR_BUF_SIZE);

  va_start(ap, fmt);
  len = vsprintf(putchar_buf, fmt, ap);
  if(len > PUTCHAR_BUF_SIZE) panic("putchar buffer not enough!");
  va_end(ap);

  for(int i = 0; i < len; i++){
    putch(putchar_buf[i]);
  }

  return len;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  size_t len = 0;
  char buffer[200];
  char *buffer_ptr = buffer + sizeof(buffer) - 1;

  while(*fmt){
    if(*fmt == '%'){
      memset(buffer, '\0', 50);
      fmt++;
      switch(*fmt++){
        case 's':
          char *s = va_arg(ap, char *);
          while(*s){
            *out++ = *s++;
            len++;
          }
          break;
        case 'c':
          char c = va_arg(ap, int);
          *out++ = c;
          len++;
          break;
        case 'd':
          int d = va_arg(ap, int);
          buffer_ptr = buffer + sizeof(buffer) - 1;
          *buffer_ptr = '\0';
          buffer_ptr--;
          bool is_negative = false;

          if(d < 0){
            is_negative = true;
            d = -d;
          }

          do{
            *buffer_ptr-- = '0' + (d % 10);
            d = d / 10;
          }while(d > 0);
          if(is_negative){
            *buffer_ptr-- = '-'; 
          }

          buffer_ptr++;
          while(*buffer_ptr){
            *out++ = *buffer_ptr++;
            len++;
          }

          break;
          case 'p':
          case 'x':
            uint32_t x = va_arg(ap, int);
            buffer_ptr = buffer + sizeof(buffer) - 1;
            *buffer_ptr = '\0';
            buffer_ptr--;
            do{
              if(x % 16 < 10) *buffer_ptr-- = '0' + (x % 16);
              else *buffer_ptr-- = 'a' + ((x % 16) - 10);
              x = x / 16;
            }while(x > 0);

            buffer_ptr++;
            while(*buffer_ptr){
              *out++ = *buffer_ptr++;
              len++;
            }

            break;
      }
    }else{
      *out++ = *fmt++;
      len++;
    }
  }

  *out = '\0';

  return len;
}

int sprintf(char *out, const char *fmt, ...) {
  va_list ap;
  size_t len = 0;

  va_start(ap, fmt);
  len = vsprintf(out, fmt, ap);
  va_end(ap);

  return len;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
