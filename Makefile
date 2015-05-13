CC=gcc
CFLAGS=-Wall -g
YACC=lemon

all: scanner

parse.c parse.h: parse.y
	$(YACC) parse.y

scanner: parse.o scanner.c
	$(CC) $(CFLAGS) -DSTANDALONE -o $@ parse.o scanner.c
