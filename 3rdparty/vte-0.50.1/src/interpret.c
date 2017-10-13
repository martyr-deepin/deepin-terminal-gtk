/*
 * Copyright (C) 2001,2002,2003 Red Hat, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include <config.h>
#include <sys/types.h>
#include <assert.h>
#include <ctype.h>
#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <glib.h>
#include <glib-object.h>
#include "caps.h"
#include "debug.h"
#include "iso2022.h"
#include "matcher.h"

int
main(int argc, char **argv)
{
	struct _vte_matcher *matcher = NULL;
	GArray *array;
	unsigned int i, j;
	int l;
	unsigned char buf[4096];
	GValue *value;
	int infile;
	struct _vte_iso2022_state *subst;
	const char *tmp;
	GValueArray *values;

	_vte_debug_init();

        if (argc < 1) {
                g_print("usage: %s [file]\n", argv[0]);
		return 1;
	}

        if ((argc > 1) && (strcmp(argv[1], "-") != 0)) {
                infile = open (argv[1], O_RDONLY);
		if (infile == -1) {
                        g_print("error opening %s: %s\n", argv[1],
				strerror(errno));
			exit(1);
		}
	} else {
		infile = 1;
	}

	g_type_init();

	array = g_array_new(FALSE, FALSE, sizeof(gunichar));

        matcher = _vte_matcher_new();

        subst = _vte_iso2022_state_new(NULL);

	for (;;) {
		l = read (infile, buf, sizeof (buf));
		if (!l)
			break;
		if (l == -1) {
			if (errno == EAGAIN)
				continue;
			exit (1);
		}
		g_array_set_size (array, 0);
		_vte_iso2022_process(subst, buf, (unsigned int) l, array);

		i = 0;
		while (i <= array->len) {
			tmp = NULL;
			values = NULL;
			for (j = 1; j < (array->len - i); j++) {
				_vte_matcher_match(matcher,
						   &g_array_index(array, gunichar, i),
						   j,
						   &tmp,
						   NULL,
						   &values);
				if ((tmp == NULL) || (strlen(tmp) > 0)) {
					break;
				}
			}
			if (i + j == array->len) {
				break;
			}
			if (tmp == NULL) {
				gunichar c;
				c = g_array_index(array, gunichar, i);
				if (c < 32) {
					g_print("`^%c'\n", c + 64);
				} else
				if (c < 127) {
					g_print("`%c'\n", c);
				} else {
					g_print("`0x%x'\n", c);
				}
				i++;
				continue;
			}

			l = j;
			g_print("%s(", tmp);
			for (j = 0; (values != NULL) && (j < values->n_values); j++) {
				if (j > 0) {
					g_print(", ");
				}
				value = g_value_array_get_nth(values, j);
				if (G_VALUE_HOLDS_LONG(value)) {
					g_print("%ld", g_value_get_long(value));
				}
				if (G_VALUE_HOLDS_STRING(value)) {
					g_print("`%s'",
						g_value_get_string(value));
				}
				if (G_VALUE_HOLDS_POINTER(value)) {
					g_print("`%ls'",
						(wchar_t*)
						g_value_get_pointer(value));
				}
			}
			if (values != NULL) {
				_vte_matcher_free_params_array(matcher, values);
			}
			g_print(")\n");
			i += l;
		}
	}
	g_print("End of data.\n");

	close (infile);

	_vte_iso2022_state_free(subst);
	g_array_free(array, TRUE);
	_vte_matcher_free(matcher);
	return 0;
}
