%include {
#include <assert.h>
#include <stdlib.h>
#include <ctype.h>
#include "scanner.h"

struct parse_expr {
	char *token; /* NULL for obj */
	struct obj *obj;
};

struct arglist {
	char *attrname; /* NULL for positional argument */
	struct parse_expr value;
	struct arglist *next;
};

struct obj {
	int id;
	char *objclass;
	struct arglist *args, *attrs;
};

struct arglist_aux {
	struct arglist *head, *tail;
};

#define MAXID 200
static int parse_current_id;

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

static
struct obj *new_obj(char *objclass, struct arglist *args, struct arglist *attrs)
{
	struct obj *c;

	c = malloc(sizeof *c);
	if (parse_current_id >= MAXID)
		printf("warning: too many children\n");
	c->id = parse_current_id++;
	c->objclass = objclass;
	c->args = args;
	c->attrs = attrs;
	return c;
}

static
struct arglist *new_arg(char *attrname, const struct parse_expr *expr)
{
	struct arglist *arg;

	arg = malloc(sizeof *arg);
	arg->attrname = attrname;
	arg->value = *expr;
	arg->next = 0;	/* so that it can be safely freed
			even if not added to a list. */
	return arg;
}

static void parse_expr_free(const struct parse_expr *);

static
void arglist_free(struct arglist *a)
{
	struct arglist *next;

	while (a) {
		scanner_free(a->attrname);
		parse_expr_free(&a->value);
		next = a->next;
		free(a);
		a = next;
	}
}

static
void obj_free(struct obj *c)
{
	scanner_free(c->objclass);
	arglist_free(c->args);
	arglist_free(c->attrs);
	free(c);
}

void parse_expr_free(const struct parse_expr *expr)
{
	if (expr->token)
		scanner_free(expr->token);
	else
		obj_free(expr->obj);
}

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
	const struct arglist *arg;

	A = B;
	printf("\t_obj[%d] = Iup%c%s(",
		A->id,
		toupper(A->objclass[0]),
		A->objclass + 1);
	for (arg = A->args; arg; arg = arg->next) {
		if (arg->value.token)
			printf("%s", arg->value.token);
		else
			printf("_obj[%d]", arg->value.obj->id);
		if (arg->next) printf(", ");
	}
	printf(");\n");
	for (arg = A->attrs; arg; arg = arg->next) {
		const char *token;

		printf("\t");
		token = arg->value.token;
		if (token) {
			printf("IupSet%s(_obj[%d], \"%s\", ",
				(token[0] == '&') ? "Callback" : "Attribute",
				A->id,
				arg->attrname);
			printf((token[0] == '&' || token[0] == '"') ? "%s);\n" : "\"%s\");\n",
				token);
		} else {
			printf("IupSetAttributeHandle(_obj[%d], \"%s\", _obj[%d]);\n",
				A->id,
				arg->attrname,
				arg->value.obj->id);
		}
	}
	printf("\n");
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
