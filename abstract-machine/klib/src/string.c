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
    *dst++ = *src++;
  }

  return original_dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  if(dst == NULL || src == NULL){
    panic("dst or src is NULL.");
  }

  if((dst >= src && dst < src + n) || (dst <= src && src < dst + n)){
    panic("dst and src that need to copy overlap.");
  }

  char *original_dst = dst;
  size_t i = 0;
  for(i = 0; i < n && *src != '\0'; i++){
    *dst++ = *src++;
  }
  for( ; i < n; i++){
    *dst++ = '\0';
  }

  return original_dst;
}

char *strcat(char *dst, const char *src) {
  if(dst == NULL || src == NULL){
    panic("dst or src is NULL.");
  }

  size_t srclen = strlen(src);
  size_t dstlen = strlen(dst);
  if((dst >= src && dst < src + srclen + 1) || (src >= dst && src < dst + dstlen + 1)){
    panic("dst and src overlap.");
  }

  char *original_dst = dst;
  dst += dstlen;
  while(*src != '\0'){
    *dst++ = *src++;
  }
  *dst++ = '\0';

  return original_dst;
}

int strcmp(const char *s1, const char *s2) {
  if(s1 == NULL || s2 == NULL){
    panic("s1 or s2 is NULL.");
  }

  while(*s1 != '\0' && *s2 != '\0'){
    if((unsigned char)*s1 != (unsigned char) *s2){
      return (unsigned char)*s1 - (unsigned char)*s2;
    }
    s1++;s2++;
  }

  return (unsigned char)*s1 - (unsigned char)*s2;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  if(s1 == NULL || s2 == NULL){
    panic("s1 or s2 is NULL.");
  }

  for(size_t i = 0; i < n && (*s1 != '\0' && (*s2 != '\0')); i++){
    if((unsigned char)*s1 != (unsigned char)*s2){
      return (unsigned char)*s1 - (unsigned char)*s2;
    }
    s1++;s2++;
  }

  return 0;
}

void *memset(void *s, int c, size_t n) {
  if(s == NULL){
    panic("s is NULL.");
  }

  unsigned char *ptr = (unsigned char *)s;
  for(size_t i = 0; i < n; i++){
    *ptr++ = (unsigned char)c;
  }

  return s;
}

void *memmove(void *dst, const void *src, size_t n) {
  if(dst == NULL || src == NULL){
    panic("dst or src is NULL.");
  }

  unsigned char *temp = (unsigned char *)malloc(n);
  if(temp == NULL){
    panic("failed to malloc.");
  }
  unsigned char *original_temp = temp;
  unsigned char *ptr_src = (unsigned char *)src;
  unsigned char *ptr_dst = (unsigned char *)dst;
  for(size_t i = 0; i < n; i++){
    *temp++ = *ptr_src++;
  }
  for(size_t i = 0; i < n; i++){
    *ptr_dst++ = *temp++;
  }

  free(original_temp);

  return dst;
}

void *memcpy(void *out, const void *in, size_t n) {
  if(out == NULL || in == NULL){
    panic("out or in is NULL.");
  }

  if((in < out && out < in + n) || (in > out && in < out + n)){
    panic("out and in overlap.");
  }

  unsigned char *ptr_out = (unsigned char *)out;
  unsigned char *ptr_in = (unsigned char *)in;
  for(size_t i = 0; i < n; i++){
    *ptr_out++ = *ptr_in++;
  }

  return out;
}

int memcmp(const void *s1, const void *s2, size_t n) {
  if(s1 == NULL || s2 == NULL){
    panic("s1 or s2 is NULL.");
  }

  unsigned char *s1_ptr = (unsigned char *)s1;
  unsigned char *s2_ptr = (unsigned char *)s2;
  for (size_t i = 0; i < n; i++){
    if(*s1_ptr != *s2_ptr){
      return *s1_ptr - *s2_ptr;
    }
    s1_ptr++;s2_ptr++;
  }

  return 0;
}

#endif
