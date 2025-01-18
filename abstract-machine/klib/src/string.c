#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  size_t len = 0;

  if(s == NULL){
    panic("s is NULL.");
  }

  for(int i = 0; ; i++){
    if(*s != '\0'){
      len++;
      s++;
    }
    else break;
  }
  return len;
}

char *strcpy(char *dst, const char *src) {
  if(dst == NULL || src == NULL){
    panic("dst or src is NULL.");
  }

  size_t srclen = strlen(src);
  if((dst >= src && dst < src + srclen + 1) || (dst <= src && src < dst + srclen + 1)){
    panic("dst and src overlap.");
  }

  char *original_dst = dst;
  for(int i = 0; i <= srclen; i++){
    *dst = *src;
    dst++;
    src++;
  }

  return original_dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  if(dst == NULL || src == NULL){
    panic("dst or src is NULL.");
  }

  if((dst >= src && dst < src + n) || (dst <= src && src < dst + n)){
    panic("dst and src that need to cpy overlap.");
  }

  char *original_dst = dst;
  size_t i = 0;
  for(i = 0; i < n && *src != '\0'; i++){
    *dst = *src;
    dst++;src++;
  }
  for( ; i < n; i++){
    *dst = '\0';
    dst++;
  }

  return original_dst;
}

char *strcat(char *dst, const char *src) {
  panic("Not implemented");
}

int strcmp(const char *s1, const char *s2) {
  panic("Not implemented");
}

int strncmp(const char *s1, const char *s2, size_t n) {
  panic("Not implemented");
}

void *memset(void *s, int c, size_t n) {
  panic("Not implemented");
}

void *memmove(void *dst, const void *src, size_t n) {
  panic("Not implemented");
}

void *memcpy(void *out, const void *in, size_t n) {
  panic("Not implemented");
}

int memcmp(const void *s1, const void *s2, size_t n) {
  panic("Not implemented");
}

#endif
