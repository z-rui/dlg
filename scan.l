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

<line>image	return IUPNAME;
<line>imagergb	return IUPNAME;
<line>imagergba	return IUPNAME;
<line>timer	return IUPNAME;
<line>user	return IUPNAME;
<line>button	return IUPNAME;
<line>canvas	return IUPNAME;
<line>dialog	return IUPNAME;
<line>fill	return IUPNAME;
<line>filedlg	return IUPNAME;
<line>messagedlg	return IUPNAME;
<line>colordlg	return IUPNAME;
<line>fontdlg	return IUPNAME;
<line>progressbar	return IUPNAME;
<line>frame	return IUPNAME;
<line>hbox	return IUPNAME;
<line>item	return IUPNAME;
<line>label	return IUPNAME;
<line>list	return IUPNAME;
<line>sbox	return IUPNAME;
<line>scrollbox	return IUPNAME;
<line>detachbox	return IUPNAME;
<line>backgroundbox	return IUPNAME;
<line>expander	return IUPNAME;
<line>menu	return IUPNAME;
<line>multiline	return IUPNAME;
<line>radio	return IUPNAME;
<line>separator	return IUPNAME;
<line>submenu	return IUPNAME;
<line>text	return IUPNAME;
<line>val	return IUPNAME;
<line>tree	return IUPNAME;
<line>tabs	return IUPNAME;
<line>toggle	return IUPNAME;
<line>vbox	return IUPNAME;
<line>zbox	return IUPNAME;
<line>gridbox	return IUPNAME;
<line>normalizer	return IUPNAME;
<line>link	return IUPNAME;
<line>cbox	return IUPNAME;
<line>spin	return IUPNAME;
<line>spinbox	return IUPNAME;
<line>split	return IUPNAME;
<line>cells	return IUPNAME;
<line>gauge	return IUPNAME;
<line>colorbar	return IUPNAME;
<line>colorbrowser	return IUPNAME;
<line>dial	return IUPNAME;
<line>matrix	return IUPNAME;
<line>matrixlist	return IUPNAME;
<line>glcanvas	return IUPNAME;
<line>matrixex	return IUPNAME;
<line>olecontrol	return IUPNAME;
<line>plot	return IUPNAME;
<line>pplot	return IUPNAME;
<line>mglplot	return IUPNAME;
<line>scintilla	return IUPNAME;
<line>webbrowser	return IUPNAME;
<line>glcanvasbox	return IUPNAME;
<line>glsubcanvas	return IUPNAME;
<line>gllabel	return IUPNAME;
<line>glseparator	return IUPNAME;
<line>glbutton	return IUPNAME;
<line>gltoggle	return IUPNAME;
<line>glprogressbar	return IUPNAME;
<line>glval	return IUPNAME;
<line>gllink	return IUPNAME;
<line>glframe	return IUPNAME;
<line>glexpander	return IUPNAME;
<line>glscrollbox	return IUPNAME;
<line>glsizebox	return IUPNAME;

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
