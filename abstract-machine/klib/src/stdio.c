#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

int printf(const char *fmt, ...) {
  panic("Not implemented");
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}

int sprintf(char *out, const char *fmt, ...) {
  va_list ap;
  size_t len = 0;
  
  va_start(ap, fmt);
  while(*fmt){
    if(*fmt == '%'){
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
          char buffer[50];
          char *buffer_ptr = buffer + sizeof(buffer) - 1;
          bool is_negetive = (d < 0) ? true : false;

          do{
            *--buffer_ptr = '0' + (d % 10);
            d = d / 10;
            len++;
          }while(d > 0);

          if(is_negetive){
            *buffer_ptr = '-'; 
            len++;
          }

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
  va_end(ap);

  *out = '\0';

  return len;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
