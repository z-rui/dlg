#ifndef SCAN_H
#define SCAN_H

struct token {
	const char *str;
	size_t length;
};

#include <stddef.h>
extern void *ParseAlloc(void *(*)(size_t));
extern void ParseFree(void *, void (*)(void *));
extern void Parse(void *, int, struct token);

#ifndef NDEBUG
#include <stdio.h>
extern void ParseTrace(FILE *, char *);
#endif

extern void scan_free(struct token);
#endif
