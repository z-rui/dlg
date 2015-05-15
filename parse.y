%include {
#include <assert.h>
#include "scanner.h"
#include "gen.h"

struct arg_aux {
	struct arglist *head, *tail;
};

static
struct arglist *arg_close(struct arg_aux *aux)
{
	if (aux->tail) aux->tail->next = 0;
	return aux->head;
}

static
void arg_open(struct arg_aux *aux, struct arglist *firstarg)
{
	aux->head = aux->tail = firstarg;
}

static
void arg_append(struct arg_aux *aux, struct arglist *item)
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
%type attrlist {struct arg_aux}
%destructor attrlist { arglist_free($$.head); }
%type arglist {struct arg_aux}
%destructor arglist { arglist_free($$.head); }
%type attr_prefix {struct arg_aux}
%destructor attr_prefix { arglist_free($$.head); }
%type objargs {struct {struct arglist *args, *attrs;}}
%destructor objargs { arglist_free($$.args); arglist_free($$.attrs); }

obj(A) ::= NAME(B) objargs(C). {
	A = new_obj(B, C.args, C.attrs);
	if (parse_current_id == MAXID)
		printf("warning: too many children\n");
	gen_obj(A, parse_current_id++);
}

objargs(A) ::= LBRACE RBRACE. {
	A.args = A.attrs = 0;
}
objargs(A) ::= LBRACE arglist(B) RBRACE. {
	A.args = arg_close(&B);
	A.attrs = 0;
}
objargs(A) ::= LBRACE attr_prefix(B) attrlist(C) RBRACE. {
	A.args = arg_close(&B);
	A.attrs = arg_close(&C);
}

attr_prefix(A) ::= SEMI. {
	arg_open(&A, 0);
}
attr_prefix(A) ::= arglist(B) SEMI. {
	A = B;
}

arglist(A) ::= expr(E). {
	arg_open(&A, new_arg(0, &E));
}
arglist(A) ::= arglist(B) COMMA expr(E). {
	A = B;
	arg_append(&A, new_arg(0, &E));
}

%type attr {struct arglist *}
%destructor attr {arglist_free($$); }

attrlist(A) ::= attr(B). {
	arg_open(&A, B);
}
attrlist(A) ::= attrlist(B) COMMA attr(C). {
	A = B;
	arg_append(&A, C);
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
