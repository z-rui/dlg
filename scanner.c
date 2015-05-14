#include "scanner.h"
#include "parse.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define IDBUFSIZ 20000

void scanner_free(char *s)
{
	free(s);
}

static int error(char *msg)
{
	fprintf(stderr, "%s\n", msg);
	exit(EXIT_FAILURE);
}

static int getchar_nonEOF(void)
{
	int ch;

	ch = getchar();
	if (ch == EOF)
		error("unexpected EOF");
	return ch;
}

static
void raw_block(int EOB)
{
	int ch;

	for (;;) {
		ch = getchar_nonEOF();
		if (ch == '%') {
			ch = getchar_nonEOF();
			if (ch == EOB)
				break;
			putchar('%');
		}
		for (;;) {
			putchar(ch);
			if (ch == '\n')
				break;
			ch = getchar_nonEOF();
		}
	}
}

static
char *bufdup(char buf[], int n)
{
	char *s;

	s = malloc(n + 1);
	memcpy(s, buf, n);
	s[n] = '\0';
	return s;
}

static
void read_line(int ch, void *parser)
{
	static char buf[IDBUFSIZ];
	int bufp;

	while (ch != '\n') {
		if (isalnum(ch) || ch == '_' || ch == '&') {
			char *token;
			int type;

			type = (isalpha(ch) || ch == '_') ? NAME :
				(isdigit(ch)) ? LITERAL : CALLBACK;
			bufp = 0;
			do {
				if (bufp == IDBUFSIZ)
					error("buffer overflow");
				buf[bufp++] = ch;
			} while (isalnum(ch = getchar_nonEOF()) || ch == '_');
			token = bufdup(buf, bufp);
			Parse(parser, type, token);
			continue; /* no need to read next char */
		} else if (ch == '"') { /* string literal */
			char *token;
			int escape = 0;

			bufp = 0;
			buf[bufp++] = '"';
			do {
				if (bufp == IDBUFSIZ)
					error("buffer overflow");
				ch = getchar_nonEOF();
				buf[bufp++] = ch;
				escape = !escape && ch == '\\';
			} while (ch != '"' || escape);
			token = bufdup(buf, bufp);
			Parse(parser, LITERAL, token);
		} else if (ch == '=') {
			Parse(parser, EQUAL, 0);
		} else if (ch == '{') {
			Parse(parser, LBRACE, 0);
		} else if (ch == '}') {
			Parse(parser, RBRACE, 0);
		} else if (ch == ';') {
			Parse(parser, SEMI, 0);  
		} else if (ch == ',') {
			Parse(parser, COMMA, 0); 
		} else if (!isspace(ch)) {
			error("unexpected token");
		}
		ch = getchar_nonEOF();
	}
}

static
void read_body(void)
{
	void *parser;
	int ch;

	parser = ParseAlloc(malloc);
	for (;;) {
		ch = getchar_nonEOF();
		if (ch == '%') {
			ch = getchar_nonEOF();
			if (ch == '{') {
				raw_block('}');
			} else if (ch == '%') {
				break;
			} else {
				putchar('%');
			}
		}
		read_line(ch, parser);
	}
	Parse(parser, 0, 0);

	ParseFree(parser, free);
}

static
void read_footer(void)
{
	int ch;

	while ((ch = getchar()) != EOF) {
		putchar(ch);
	}
}

#ifdef STANDALONE
int main()
{
	raw_block('%');
	read_body();
	read_footer();
	return 0;
}
#endif
