#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "parse.h"
#include "scan.h"
#include "gen.h"

static char *YYCURSOR, *YYLIMIT, *YYMARKER;

/*!re2c
re2c:define:YYCTYPE = char;
re2c:yyfill:enable = 0;

EOF = "\000";
IDENT = [_A-Za-z][_A-Za-z0-9]+;
INTEGER = [0-9]+;

*/

static
void error(const char *context)
{
	if (context == 0)
		fprintf(stderr, "premature EOF\n");
	else
		fprintf(stderr, "syntax error near '%.10s'\n", context);
	exit(1);
}

static
void read_header(void)
{
	char *save;
initial:
	save = YYCURSOR;
/*!re2c
"%%"	{ return; }
[^]	{ YYCURSOR = save; goto line; }
*/
line:
	save = YYCURSOR;
/*!re2c
EOF	{ error(0); }
[^]	{
	putchar(*save);
	if (*save == '\n')
		goto initial;
	else
		goto line;
}
*/
}

static
int next_token(char **save, int *state)
{
	switch (*state) {
		case 0: goto initial;
		case 1: goto line;
	}
initial:
	*save = YYCURSOR;
	*state = 0;
/*!re2c
"%%"	{ return 0; }
[^]	{ YYCURSOR = *save; goto line; }
*/
line:
	*save = YYCURSOR;
	*state = 1;
/*!re2c
EOF	{ error(0); }
"\n"	{ goto initial; }
[\t\r\v ]	{ goto line; }
"\""	{ goto str; }
IDENT	{
	struct token token = { *save, YYCURSOR - *save };
	const char *p, *q;

	get_control_info(token, &p, &q);
	if (p)
		return IUPNAME;
	return NAME;
}
INTEGER	{ return LITERAL; }
"&" IDENT	{ return CALLBACK; }
"="	{ return EQUAL; }
"{"	{ return LBRACE; }
"}"	{ return RBRACE; }
";"	{ return SEMI; }
","	{ return COMMA; }
[^]	{ error(*save); }
*/
str:
	/* no save (lexeme accumulates) */
	/* no state (never yields within this state) */
/*!re2c
EOF	{ error(0); }
"\\\""	{ goto str; }
"\""	{ return LITERAL; }
[^]	{ goto str; }
*/
}

static
void read_footer(void)
{
	char ch;
initial:
	ch = *YYCURSOR;
/*!re2c
	EOF	{ return; }
	[^]	{ putchar(ch); goto initial; }
*/
}

static
void load_buffer(void)
{
	static char buffer[65536];
	size_t len;
#if 1
	len = fread(buffer, 1, sizeof buffer, stdin);
	if (len >= sizeof buffer) {
		fprintf(stderr, "input too large\n");
		exit(1);
	}
#else
	len = strlen(buffer);
#endif
	YYCURSOR = buffer;
	YYLIMIT = buffer + len + 1;
	buffer[len] = '\0';
}

void scan_free(struct token token)
{
	(void) token; /* nothing to do! */
}

static
void read_body(void)
{
	void *parser;
	int state, major;
	char *save;

	parser = ParseAlloc(malloc);
	//ParseTrace(stderr, "Parse: ");
	state = 0;
	do {
		struct token minor;

		major = next_token(&save, &state);
		minor.str = save;
		minor.length = YYCURSOR - save;
		Parse(parser, major, minor);
	} while (major);
	ParseFree(parser, free);
}

int main()
{
	load_buffer();

	read_header();
	read_body();
	read_footer();

	return 0;
}

/* vim: set ft=c: */
