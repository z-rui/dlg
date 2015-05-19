#ifndef SCAN_H
#define SCAN_H

#include <stddef.h>
extern void *ParseAlloc(void *(*)(size_t));
extern void ParseFree(void *, void (*)(void *));
extern void Parse(void *, int, char *);

#ifndef NDEBUG
#include <stdio.h>
extern void ParseTrace(FILE *, char *);
#endif

extern void scan_free(char *);
#endif
