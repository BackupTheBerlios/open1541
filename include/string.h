
#ifndef _STRING_H
#define _STRING_H

#include <stddef.h>

void *memset(void *s, int c, size_t n);
void *memmove(void *dest, const void *src, size_t n);
size_t strlen(const char *s);
int memcmp(const void *s1, const void *s2, size_t n);
int strncmp(const char *s1, const char *s2, size_t n);
int strcmp(const char *s1, const char *s2);
char *strcpy(char *s1, const char *s2);

#endif
