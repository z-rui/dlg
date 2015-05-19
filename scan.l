%{
#include <stdlib.h>
#include "parse.h"
#include "scan.h"
%}

%option noyywrap
%x line_initial line
%x raw_initial raw_line
%x str

IDENT	[_A-Za-z][_A-Za-z0-9]*
INTEGER	[0-9]+

%%
<INITIAL>.|\n	BEGIN(raw_initial); yyless(0);

<raw_initial>"%%" {
		BEGIN(line);
}
<raw_initial>.	BEGIN(raw_line); yyless(0);

<raw_line>"\n"	ECHO; BEGIN(raw_initial);

<line_initial>"%%" {
		BEGIN(raw_line);
		return RAW_BLOCK;
}
<line_initial>"\n" /* IGNORE */
<line_initial>.	BEGIN(line); yyless(0);

<line>&{IDENT}	return CALLBACK;
<line>{IDENT}	return NAME;
<line>{INTEGER} return LITERAL;
<line>"="	return EQUAL;
<line>"{"	return LBRACE;
<line>"}"	return RBRACE;
<line>";"	return SEMI;
<line>","	return COMMA;
<line>"\""	BEGIN(str); yymore();
<line>"\n"	BEGIN(line_initial);
<line>[\t\r\v ]	/* IGNORE */
<line>.	{
	printf("syntax error near %s\n", yytext);
	exit(1);
}

<str>"\\\""	yymore();
<str>"\""	BEGIN(line); return LITERAL;
<str>.|\n	yymore();

%%

void scan_free(char *s)
{
	free(s);
}

static
char *bufdup(const char *s, size_t n)
{
	char *t;

	t = malloc(n + 1);
	return strcpy(t, s);
}

int main()
{
	void *parser;
	int token;

	parser = ParseAlloc(malloc);
	do {
		token = yylex();
		Parse(parser, token, bufdup(yytext, yyleng));
	} while (token);
	ParseFree(parser, free);
	return 0;
}
