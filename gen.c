#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <assert.h>
#include "scan.h"
#include "gen.h"

#define IUP_VARARG 0
#define IUP_NOVARARG ""

static
struct {
	const char *proper_case;
	const char *arginfo;
} control_info[] = {
	{ "Image",        IUP_NOVARARG },
	{ "ImageRGB",     IUP_NOVARARG },
	{ "ImageRGBA",    IUP_NOVARARG },
	{ "Timer",        IUP_NOVARARG },
	{ "User",         IUP_NOVARARG },
	{ "Button",       IUP_NOVARARG },
	{ "Canvas",       IUP_NOVARARG },
	{ "Dialog",       IUP_NOVARARG },
	{ "Fill",         IUP_NOVARARG },
	{ "FileDlg",      IUP_NOVARARG },
	{ "MessageDlg",   IUP_NOVARARG },
	{ "ColorDlg",     IUP_NOVARARG },
	{ "FontDlg",      IUP_NOVARARG },
	{ "ProgressBar",  IUP_NOVARARG },
	{ "Frame",        IUP_NOVARARG },
	{ "Hbox",         IUP_VARARG   },
	{ "Item",         IUP_NOVARARG },
	{ "Label",        IUP_NOVARARG },
	{ "List",         IUP_NOVARARG },
	{ "Sbox",         IUP_NOVARARG },
	{ "ScrollBox",    IUP_NOVARARG },
	{ "DetachBox",    IUP_NOVARARG },
	{ "BackgroundBox",IUP_NOVARARG },
	{ "Expander",     IUP_NOVARARG },
	{ "Menu",         IUP_VARARG   },
	{ "MultiLine",    IUP_NOVARARG },
	{ "Radio",        IUP_NOVARARG },
	{ "Separator",    IUP_NOVARARG },
	{ "Submenu",      IUP_NOVARARG },
	{ "Text",         IUP_NOVARARG },
	{ "Val",          IUP_NOVARARG },
	{ "Tree",         IUP_NOVARARG },
	{ "Tabs",         IUP_VARARG   },
	{ "Toggle",       IUP_NOVARARG },
	{ "Vbox",         IUP_VARARG   },
	{ "Zbox",         IUP_VARARG   },
	{ "GridBox",      IUP_VARARG   },
	{ "Normalizer",   IUP_VARARG   },
	{ "Link",         IUP_NOVARARG },
	{ "Cbox",         IUP_NOVARARG },
	{ "Spin",         IUP_NOVARARG },
	{ "Spinbox",      IUP_NOVARARG },
	{ "Split",        IUP_NOVARARG },
	{ "Cells",        IUP_NOVARARG },
	{ "Gauge",        IUP_NOVARARG },
	{ "Colorbar",     IUP_NOVARARG },
	{ "ColorBrowser", IUP_NOVARARG },
	{ "Dial",         IUP_NOVARARG },
	{ "Matrix",       IUP_NOVARARG },
	{ "MatrixList",   IUP_NOVARARG },
	{ "GLCanvas",     IUP_NOVARARG },
	{ "MatrixEx",     IUP_NOVARARG },
	{ "OleControl",   IUP_NOVARARG },
	{ "Plot",         IUP_NOVARARG },
	{ "PPlot",        IUP_NOVARARG },
	{ "MglPlot",      IUP_NOVARARG },
	{ "Scintilla",    IUP_NOVARARG },
	{ "WebBrowser",   IUP_NOVARARG },
	{ "GLCanvasBox",  IUP_VARARG   },
	{ "GLSubCanvas",  IUP_NOVARARG },
	{ "GLLabel",      IUP_NOVARARG },
	{ "GLSeparator",  IUP_NOVARARG },
	{ "GLButton",     IUP_NOVARARG },
	{ "GLToggle",     IUP_NOVARARG },
	{ "GLProgressBar",IUP_NOVARARG },
	{ "GLVal",        IUP_NOVARARG },
	{ "GLLink",       IUP_NOVARARG },
	{ "GLFrame",      IUP_NOVARARG },
	{ "GLExpander",   IUP_NOVARARG },
	{ "GLScrollBox",  IUP_NOVARARG },
	{ "GLSizeBox",    IUP_NOVARARG },
	{ 0, 0 }
};

static
int strncmp_lower_vs_anycase(const char *s, const char *t, size_t n)
{
	int diff;

	while (n-- > 0 && (diff = *s - tolower(*t)) == 0 && *s)
		s++, t++;
	return diff;
}

void print_token(struct token token)
{
	printf("%.*s", (int) token.length, token.str);
}

void get_control_info(struct token token, const char **proper_case, const char **arginfo)
{
	int i;

	for (i = 0; control_info[i].proper_case; i++) {
		/* we know that token is all lower case */
		if (strncmp_lower_vs_anycase(token.str, control_info[i].proper_case, token.length) == 0)
			break;
	}
	*proper_case = control_info[i].proper_case;
	*arginfo = control_info[i].arginfo;
}

struct obj *new_obj(struct token objclass, struct arglist *args, struct arglist *attrs)
{
	struct obj *c;

	c = malloc(sizeof *c);
	c->objclass = objclass;
	c->args = args;
	c->attrs = attrs;
	return c;
}

struct arglist *new_arg(struct token attrname, const struct parse_expr *expr)
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
		scan_free(a->attrname);
		parse_expr_free(&a->value);
		next = a->next;
		free(a);
		a = next;
	}
}

void obj_free(struct obj *c)
{
	scan_free(c->objclass);
	arglist_free(c->args);
	arglist_free(c->attrs);
	free(c);
}

void parse_expr_free(const struct parse_expr *expr)
{
	if (expr->token.str)
		scan_free(expr->token);
	else
		obj_free(expr->obj);
}

void gen_obj(struct obj *o, int id)
{
	const struct arglist *arg;
	const char *proper_case, *arginfo;

	o->id = id;
	get_control_info(o->objclass, &proper_case, &arginfo);
	if (!proper_case) {
		fprintf(stderr, "warning: unknown control '%.*s'\n", (int) o->objclass.length, o->objclass.str);
	}
	assert(proper_case);
	printf("\t_obj[%d] = Iup%s(",
		o->id,
		proper_case);
	for (arg = o->args; arg; arg = arg->next) {
		if (arg->value.token.str)
			print_token(arg->value.token);
		else
			printf("_obj[%d]", arg->value.obj->id);
		if (arg->next) printf(", ");
	}
	if (arginfo == IUP_VARARG)
		printf(", 0");
	printf(");\n");
	for (arg = o->attrs; arg; arg = arg->next) {
		struct token token;

		printf("\t");
		token = arg->value.token;
		if (token.str) {
			char startch;

			startch = token.str[0];
			printf("IupSet%s(_obj[%d], \"",
				(startch == '&') ? "Callback" : "Attribute",
				o->id);
			print_token(arg->attrname);
			printf("\", ");
			print_token(token);
			printf(");\n");
		} else {
			printf("IupSetAttributeHandle(_obj[%d], \"", o->id);
			print_token(arg->attrname);
			printf("\", _obj[%d]);\n", arg->value.obj->id);
		}
	}
	printf("\n");
}
