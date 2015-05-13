%include {
#include <assert.h>
#include "scanner.h"
}

%token_type{char *}
%token_destructor{ scanner_free($$); }

input ::= body.

body ::=.
body ::= body definition. 

definition ::= NAME EQUAL constructor. 

constructor ::= NAME LBRACE RBRACE.
constructor ::= NAME LBRACE arglist RBRACE.
constructor ::= NAME LBRACE attr_prefix attrlist RBRACE.

attr_prefix ::= SEMI.
attr_prefix ::= arglist SEMI.

arglist ::= expr.
arglist ::= arglist COMMA expr. 

attrlist ::= attr.
attrlist ::= attrlist COMMA attr.

attr ::= NAME EQUAL expr. 

expr ::= LITERAL.
expr ::= CALLBACK.
expr ::= constructor.

