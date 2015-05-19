#ifndef GEN_H
#define GEN_H

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

extern void get_control_info(const char *, const char **, const char **);
extern struct obj *new_obj(char *, struct arglist *, struct arglist *);
extern struct arglist *new_arg(char *, const struct parse_expr *);
extern void arglist_free(struct arglist *);
extern void obj_free(struct obj *);
extern void parse_expr_free(const struct parse_expr *);
extern void gen_obj(struct obj *, int);

#endif
