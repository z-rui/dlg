#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "scanner.h"
#include "gen.h"

struct obj *new_obj(char *objclass, struct arglist *args, struct arglist *attrs)
{
	struct obj *c;

	c = malloc(sizeof *c);
	c->objclass = objclass;
	c->args = args;
	c->attrs = attrs;
	return c;
}

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

void gen_obj(struct obj *o, int id)
{
	const struct arglist *arg;

	o->id = id;
	printf("\t_obj[%d] = Iup%c%s(",
		o->id,
		toupper(o->objclass[0]),
		o->objclass + 1);
	for (arg = o->args; arg; arg = arg->next) {
		if (arg->value.token)
			printf("%s", arg->value.token);
		else
			printf("_obj[%d]", arg->value.obj->id);
		if (arg->next) printf(", ");
	}
	printf(");\n");
	for (arg = o->attrs; arg; arg = arg->next) {
		const char *token;

		printf("\t");
		token = arg->value.token;
		if (token) {
			printf("IupSet%s(_obj[%d], \"%s\", ",
				(token[0] == '&') ? "Callback" : "Attribute",
				o->id,
				arg->attrname);
			printf((token[0] == '&' || token[0] == '"') ? "%s);\n" : "\"%s\");\n",
				token);
		} else {
			printf("IupSetAttributeHandle(_obj[%d], \"%s\", _obj[%d]);\n",
				o->id,
				arg->attrname,
				arg->value.obj->id);
		}
	}
	printf("\n");
}
