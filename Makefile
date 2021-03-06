CC=gcc
CFLAGS=-Wall -g
YACC=lemon
LEX=re2c

all: scan

parse.c parse.h: parse.y
	$(YACC) parse.y

scan: parse.o gen.o scan.c
	$(CC) $(CFLAGS) -DSTANDALONE -o $@ parse.o gen.o scan.c

scan.c: scan.re
	$(LEX) -o $@ $<

clean:
	rm -f *.o parse.c parse.h parse.out scan.c

.PHONY: all clean
