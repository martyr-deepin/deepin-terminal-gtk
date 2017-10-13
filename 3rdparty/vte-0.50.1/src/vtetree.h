/*
 * Copyright (C) 2004 Benjamin Otte <otte@gnome.org>
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

/* The interfaces in this file are subject to change at any time. */

#ifndef vte_tree_h_included
#define vte_tree_h_included


#include <glib.h>

G_BEGIN_DECLS

/* This is an optimiziation for GTrees we use with unicode characters. Since
 * most characters are in the range [0-128], we store that range in an array
 * for faster access.
 * We match the API for GTree here.
 */
#define VTE_TREE_ARRAY_SIZE (128)

typedef struct _VteTree VteTree;
struct _VteTree {
  GTree *tree;
  gpointer array[VTE_TREE_ARRAY_SIZE];
};

VteTree *_vte_tree_new(GCompareFunc key_compare_func);
void _vte_tree_destroy(VteTree *tree);
void _vte_tree_insert(VteTree *tree, gpointer key, gpointer value);
gpointer _vte_tree_lookup(VteTree *tree, gconstpointer key);
/* extend as needed */

G_END_DECLS

#endif
