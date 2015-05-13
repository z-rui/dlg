#ifndef SCANNER_H
#define SCANNER_H

#define IDBUFSIZ 20

#include <stddef.h>
extern void *ParseAlloc(void *(*)(size_t));
extern void ParseFree(void *, void (*)(void *));
extern void Parse(void *, int, char *);

#ifndef NDEBUG
#include <stdio.h>
extern void ParseTrace(FILE *, char *);
#endif

extern void scanner_free(char *);
#endif
