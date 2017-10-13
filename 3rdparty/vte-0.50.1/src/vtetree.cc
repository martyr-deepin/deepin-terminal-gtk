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

#include "vtetree.h"

VteTree *
_vte_tree_new(GCompareFunc key_compare_func)
{
  VteTree *tree = g_slice_new0 (VteTree);
  tree->tree = g_tree_new (key_compare_func);
  return tree;
}

void 
_vte_tree_destroy(VteTree *tree)
{
  g_tree_destroy (tree->tree);
  g_slice_free (VteTree, tree);
}

void 
_vte_tree_insert(VteTree *tree, gpointer key, gpointer value)
{
  guint index = GPOINTER_TO_UINT (key);
  
  if (index < VTE_TREE_ARRAY_SIZE) {
    tree->array[index] = value;
    return;
  }
  g_tree_insert (tree->tree, key, value);
}

gpointer
_vte_tree_lookup(VteTree *tree, gconstpointer key)
{
  const guint index = GPOINTER_TO_UINT (key);
  
  if (index < VTE_TREE_ARRAY_SIZE)
    return tree->array[index];

  return g_tree_lookup (tree->tree, key);
}

