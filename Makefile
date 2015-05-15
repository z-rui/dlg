CC=gcc
CFLAGS=-Wall -g
YACC=lemon

all: scanner

parse.c parse.h: parse.y
	$(YACC) parse.y

scanner: parse.o gen.o scanner.c
	$(CC) $(CFLAGS) -DSTANDALONE -o $@ parse.o gen.o scanner.c

clean:
	rm -f *.o parse.c parse.h parse.out

.PHONY: all clean
