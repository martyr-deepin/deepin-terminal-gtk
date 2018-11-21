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
#include <locale.h>
#include "caps.hh"
#include "debug.h"
#include "iso2022.h"
#include "matcher.hh"

static bool quiet = false;

static void
print_array(GValueArray* array)
{
        GValue *value;
        if (array != NULL) {
                g_print("(");
                for (unsigned int i = 0; i < array->n_values; i++) {
                        value = g_value_array_get_nth(array, i);
                        if (i > 0) {
                                g_print(", ");
                        }
                        if (G_VALUE_HOLDS_LONG(value)) {
                                g_print("%ld", g_value_get_long(value));
                        } else
                        if (G_VALUE_HOLDS_STRING(value)) {
                                g_print("\"%s\"", g_value_get_string(value));
                        } else
                        if (G_VALUE_HOLDS_POINTER(value)) {
                                g_print("\"%ls\"",
                                        (wchar_t*) g_value_get_pointer(value));
                        } else
                        if (G_VALUE_HOLDS_BOXED(value)) {
                                print_array((GValueArray *)g_value_get_boxed(value));
                        }
                }
                g_print(")");
        }
}

namespace vte { namespace parser { struct Params { GValueArray *m_values; }; } }

class VteTerminalPrivate {
public:
#define SEQUENCE_HANDLER(name) \
	inline void seq_ ## name (vte::parser::Params const& params) { \
                if (!quiet) { \
                        g_print (G_STRINGIFY(name)); \
                        print_array(params.m_values); \
                        g_print("\n"); \
                } \
        }
#include "vteseq-list.hh"
#undef SEQUENCE_HANDLER
};

vte_matcher_entry_t const*
_vte_get_matcher_entries(unsigned int* n_entries)
{
#include "caps-list.hh"
        *n_entries = G_N_ELEMENTS (entries);
        return entries;
}

int
main(int argc, char **argv)
{
	struct _vte_matcher *matcher = NULL;
	GArray *array;
	unsigned char buf[4096];
	int infile;
	struct _vte_iso2022_state *subst;

        setlocale(LC_ALL, "");

	_vte_debug_init();

        if (argc < 1) {
                g_print("usage: %s [file] [--quiet]\n", argv[0]);
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

        if (argc > 2)
                quiet = g_str_equal(argv[2], "--quiet") || g_str_equal(argv[2], "-q");

	g_type_init();

	array = g_array_new(FALSE, FALSE, sizeof(gunichar));

        matcher = _vte_matcher_new();

        subst = _vte_iso2022_state_new(NULL);

        VteTerminalPrivate terminal{};
        gsize n_seq = 0;
        gsize n_chars = 0;
        gsize n_discarded = 0;

        gsize start = 0;

	for (;;) {
		auto l = read (infile, buf, sizeof (buf));
		if (!l)
			break;
		if (l == -1) {
			if (errno == EAGAIN)
				continue;
			break;
		}
		_vte_iso2022_process(subst, buf, (unsigned int) l, array);

                gunichar* wbuf = &g_array_index(array, gunichar, 0);
                gsize wcount = array->len;

                bool leftovers = false;

                while (start < wcount && !leftovers) {
                        const gunichar *next;
                        vte::parser::Params params{nullptr};
                        sequence_handler_t handler = nullptr;
                        auto match_result = _vte_matcher_match(matcher,
                                                               &wbuf[start],
                                                               wcount - start,
                                                               &handler,
                                                               &next,
                                                               &params.m_values);
                        switch (match_result) {
                        case VTE_MATCHER_RESULT_MATCH: {
                                (terminal.*handler)(params);
                                if (params.m_values != nullptr)
                                        _vte_matcher_free_params_array(matcher, params.m_values);

                                /* Skip over the proper number of unicode chars. */
                                start = (next - wbuf);
                                n_seq++;
                                break;
                        }
                        case VTE_MATCHER_RESULT_NO_MATCH: {
                                auto c = wbuf[start];
                                /* If it's a control character, permute the order, per
                                 * vttest. */
                                if ((c != *next) &&
                                    ((*next & 0x1f) == *next) &&
                                    //FIXMEchpe what about C1 controls
                                    (gssize(start + 1) < next - wbuf)) {
                                        const gunichar *tnext = nullptr;
                                        gunichar ctrl;
                                        /* We don't want to permute it if it's another
                                         * control sequence, so check if it is. */
                                        sequence_handler_t thandler;
                                        _vte_matcher_match(matcher,
                                                           next,
                                                           wcount - (next - wbuf),
                                                           &thandler,
                                                           &tnext,
                                                           nullptr);
                                        /* We only do this for non-control-sequence
                                         * characters and random garbage. */
                                        if (tnext == next + 1) {
                                                /* Save the control character. */
                                                ctrl = *next;
                                                /* Move everything before it up a
                                                 * slot.  */
                                                // FIXMEchpe memmove!
                                                gsize i;
                                                for (i = next - wbuf; i > start; i--) {
                                                        wbuf[i] = wbuf[i - 1];
                                                }
                                                /* Move the control character to the
                                                 * front. */
                                                wbuf[i] = ctrl;
                                                goto next_match;
                                        }
                                }
                                n_chars++;
                                if (!quiet) {
                                        if (c < 32) {
                                                g_print("`^%c'\n", c + 64);
                                        } else
                                                if (c < 127) {
                                                        g_print("`%c'\n", c);
                                                } else {
                                                        g_print("`0x%x'\n", c);
                                                }
                                }
                                start++;
                                break;
                        }
                        case VTE_MATCHER_RESULT_PARTIAL: {
                                if (wbuf + wcount > next) {
                                        if (!quiet)
                                                g_print("Invalid control "
                                                        "sequence, discarding %ld "
                                                        "characters.\n",
                                                        (long)(next - (wbuf + start)));
                                        /* Discard. */
                                        start = next - wbuf + 1;
                                        n_discarded += next - &wbuf[start];
                                } else {
                                        /* Pause processing here and wait for more
                                         * data before continuing. */
                                        leftovers = true;
                                }
                                break;
                        }
                        }

		}

        next_match:
                if (start < wcount) {
                        g_array_remove_range(array, 0, start);
                        start = wcount - start;
                } else {
                        g_array_set_size(array, 0);
                        start = 0;
                }
	}
        if (!quiet)
                g_print("End of data.\n");

        g_printerr ("Characters inserted:  %" G_GSIZE_FORMAT "\n"
                    "Sequences recognised: %" G_GSIZE_FORMAT "\n"
                    "Bytes discarded:      %" G_GSIZE_FORMAT "\n",
                    n_chars, n_seq, n_discarded);

	close (infile);

	_vte_iso2022_state_free(subst);
	g_array_free(array, TRUE);
	_vte_matcher_free(matcher);
	return 0;
}
