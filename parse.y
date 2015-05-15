%include {
#include <assert.h>
#include "scanner.h"
#include "gen.h"

struct arglist_aux {
	struct arglist *head, *tail;
};

static
struct arglist *arglist_close(struct arglist_aux *aux)
{
	if (aux->tail) aux->tail->next = 0;
	return aux->head;
}

static
void arglist_open(struct arglist_aux *aux, struct arglist *firstarg)
{
	aux->head = aux->tail = firstarg;
}

static
void arglist_append(struct arglist_aux *aux, struct arglist *item)
{
	assert(item);
	if (aux->tail) {
		aux->tail = aux->tail->next = item;
	} else {
		aux->head = aux->tail = item;
	}
}

#define MAXID 200
int parse_current_id;

} /* %include */

%token_type{char *}
%token_destructor{ scanner_free($$); }

input ::= body.

body ::=.
body ::= body definition. 

%type obj {struct obj *}
%destructor obj {obj_free($$); }

definition ::= defname EQUAL obj(A). {
	printf("\treturn _obj[%d];\n}\n\n", A->id);
	obj_free(A);
}

defname ::= NAME(A). {
	printf("Ihandle *%s(void)\n{\n", A);
	printf("\tIhandle *_obj[%d];\n\n", MAXID);
	scanner_free(A);
	parse_current_id = 0;
}

/* these are by-value objects, no need to be freed.
 * BUT the entries stored in need to be freed. */
%type attrlist {struct arglist_aux}
%destructor attrlist { arglist_free($$.head); }
%type arglist {struct arglist_aux}
%destructor arglist { arglist_free($$.head); }
%type attr_prefix {struct arglist_aux}
%destructor attr_prefix { arglist_free($$.head); }

obj(A) ::= objdef(B). {
	A = B;
	if (parse_current_id == MAXID)
		printf("warning: too many children\n");
	gen_obj(A, parse_current_id++);
}

%type objdef {struct obj *}
%destructor objdef {obj_free($$); }

objdef(A) ::= NAME(B) LBRACE RBRACE. {
	A = new_obj(B, 0, 0);
}
objdef(A) ::= NAME(B) LBRACE arglist(C) RBRACE. {
	A = new_obj(B, arglist_close(&C), 0);
}
objdef(A) ::= NAME(B) LBRACE attr_prefix(C) attrlist(D) RBRACE. {
	A = new_obj(B, arglist_close(&C), arglist_close(&D));
}

attr_prefix(A) ::= SEMI. {
	arglist_open(&A, 0);
}
attr_prefix(A) ::= arglist(B) SEMI. {
	A = B;
}

arglist(A) ::= expr(E). {
	arglist_open(&A, new_arg(0, &E));
}
arglist(A) ::= arglist(B) COMMA expr(E). {
	A = B;
	arglist_append(&A, new_arg(0, &E));
}

%type attr {struct arglist *}
%destructor attr {arglist_free($$); }

attrlist(A) ::= attr(B). {
	arglist_open(&A, B);
}
attrlist(A) ::= attrlist(B) COMMA attr(C). {
	A = B;
	arglist_append(&A, C);
}

%type expr {struct parse_expr}
%destructor expr {parse_expr_free(&$$); }

attr(A) ::= NAME(B) EQUAL expr(C). {
	A = new_arg(B, &C);
}

expr(A) ::= LITERAL(B). {
	A.token = B;
}
expr(A) ::= CALLBACK(B). {
	A.token = B;
}
expr(A) ::= obj(B). {
	A.token = 0;
	A.obj = B;
}
