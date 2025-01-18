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
    switch(*fmt++){
      case 's':
        char *s = va_arg(ap, char *);
        len += strlen(s);
        strcat(out, s);
        break;
      case 'c':
        char c = va_arg(ap, int);
        len += 1;
        *out++ = c;
        break;
    }
  }
  va_end(ap);

  out++;
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
