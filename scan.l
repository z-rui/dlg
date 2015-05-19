%{
#include <stdlib.h>
#include "parse.h"
%}

%option noyywrap
%x line_initial line
%x raw_initial raw_line
%x str

IDENT	[_A-Za-z][_A-Za-z0-9]*
INTEGER	[0-9]+

%%
<INITIAL>.|\n	BEGIN(raw_initial); yyless(0);

<raw_initial>"%%"	BEGIN(line);
<raw_initial>.	BEGIN(raw_line); yyless(0);

<raw_line>"\n"	ECHO; BEGIN(raw_initial);

<line_initial>"%%"	BEGIN(raw_line);
<line_initial>"\n"	/* IGNORE */
<line_initial>.	BEGIN(line); yyless(0);

<line>"&"{IDENT}	return CALLBACK;
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

int main()
{
	int token;

	do {
		token = yylex();
		printf("%d\t%s\n", token, yytext);
	} while (token);
	return 0;
}
