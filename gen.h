#ifndef GEN_H
#define GEN_H

#include "scan.h"

struct parse_expr {
	struct token token; /* NULL for obj */
	struct obj *obj;
};

struct arglist {
	struct token attrname; /* NULL for positional argument */
	struct parse_expr value;
	struct arglist *next;
};

struct obj {
	int id;
	struct token objclass;
	struct arglist *args, *attrs;
};

extern void print_token(struct token token);
extern void get_control_info(struct token, const char **, const char **);
extern struct obj *new_obj(struct token, struct arglist *, struct arglist *);
extern struct arglist *new_arg(struct token, const struct parse_expr *);
extern void arglist_free(struct arglist *);
extern void obj_free(struct obj *);
extern void parse_expr_free(const struct parse_expr *);
extern void gen_obj(struct obj *, int);

#endif
