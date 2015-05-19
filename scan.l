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

<line>image	|
<line>imagergb	|
<line>imagergba	|
<line>timer	|
<line>user	|
<line>button	|
<line>canvas	|
<line>dialog	|
<line>fill	|
<line>filedlg	|
<line>messagedlg	|
<line>colordlg	|
<line>fontdlg	|
<line>progressbar	|
<line>frame	|
<line>hbox	|
<line>item	|
<line>label	|
<line>list	|
<line>sbox	|
<line>scrollbox	|
<line>detachbox	|
<line>backgroundbox	|
<line>expander	|
<line>menu	|
<line>multiline	|
<line>radio	|
<line>separator	|
<line>submenu	|
<line>text	|
<line>val	|
<line>tree	|
<line>tabs	|
<line>toggle	|
<line>vbox	|
<line>zbox	|
<line>gridbox	|
<line>normalizer	|
<line>link	|
<line>cbox	|
<line>spin	|
<line>spinbox	|
<line>split	|
<line>cells	|
<line>gauge	|
<line>colorbar	|
<line>colorbrowser	|
<line>dial	|
<line>matrix	|
<line>matrixlist	|
<line>glcanvas	|
<line>matrixex	|
<line>olecontrol	|
<line>plot	|
<line>pplot	|
<line>mglplot	|
<line>scintilla	|
<line>webbrowser	|
<line>glcanvasbox	|
<line>glsubcanvas	|
<line>gllabel	|
<line>glseparator	|
<line>glbutton	|
<line>gltoggle	|
<line>glprogressbar	|
<line>glval	|
<line>gllink	|
<line>glframe	|
<line>glexpander	|
<line>glscrollbox	|
<line>glsizebox	return IUPNAME;

<line>{IDENT}	return NAME;
<line>{INTEGER}	return LITERAL;

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
