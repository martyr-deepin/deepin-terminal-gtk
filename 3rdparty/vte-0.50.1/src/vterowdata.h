/*
 * Copyright (C) 2002 Red Hat, Inc.
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

#ifndef vterowdata_h_included
#define vterowdata_h_included

#include <string.h>

#include "vteunistr.h"
#include "vtemacros.h"
#include "vtedefines.hh"

G_BEGIN_DECLS

#define VTE_TAB_WIDTH_BITS		4  /* Has to be able to store the value of 8. */
#define VTE_TAB_WIDTH_MAX		((1 << VTE_TAB_WIDTH_BITS) - 1)

#define VTE_CELL_ATTR_COMMON_BYTES      8  /* The number of common bytes in VteCellAttr and VteStreamCellAttr */

/*
 * VteCellAttr: A single cell style attributes
 *
 * When adding new attributes, keep in sync with VteStreamCellAttr and
 * update VTE_CELL_ATTR_COMMON_BYTES accordingly.
 * Also don't forget to update basic_cell below!
 */

typedef struct _VteCellAttr {
	guint64 fragment: 1;	/* A continuation cell. */
	guint64 columns: VTE_TAB_WIDTH_BITS;	/* Number of visible columns
						   (as determined by g_unicode_iswide(c)).
						   Also abused for tabs; bug 353610
						   */
	guint64 bold: 1;
	guint64 italic: 1;
	guint64 fore: 25;	/* Index into color palette, or direct RGB, */
	/* 4-byte boundary */
	guint64 back: 25;	/* see vtedefines.hh */

	guint64 underline: 1;
	guint64 strikethrough: 1;

	guint64 reverse: 1;
	guint64 blink: 1;
	guint64 dim: 1;		/* also known as faint, half intensity etc. */

	guint64 invisible: 1;
        guint64 padding_unused_1: 1;
        /* 8-byte boundary */
        guint32 hyperlink_idx;  /* a unique hyperlink index at a time for the ring's cells,
                                   0 means not a hyperlink, VTE_HYPERLINK_IDX_TARGET_IN_STREAM
                                   means the target is irrelevant/unknown at the moment.
                                   If bitpacking, choose a size big enough to hold a different idx
                                   for every cell in the ring but not yet in the stream
                                   (currently the height rounded up to the next power of two, times width)
                                   for supported VTE sizes, and update VTE_HYPERLINK_IDX_TARGET_IN_STREAM. */
        guint32 padding_unused_2;
} VteCellAttr;
G_STATIC_ASSERT (sizeof (VteCellAttr) == 16);
G_STATIC_ASSERT (offsetof (VteCellAttr, hyperlink_idx) == VTE_CELL_ATTR_COMMON_BYTES);

/*
 * VteStreamCellAttr: Variant of VteCellAttr to be stored in attr_stream.
 *
 * When adding new attributes, keep in sync with VteCellAttr and
 * update VTE_CELL_ATTR_COMMON_BYTES accordingly.
 */

typedef struct _VTE_GNUC_PACKED _VteStreamCellAttr {
        guint64 fragment: 1;
        guint64 columns: VTE_TAB_WIDTH_BITS;
        guint64 remaining_main_attributes: 59;  /* All the non-hyperlink related attributes from VteCellAttr.
                                                   We don't individually access them in the stream, so there's
                                                   no point in repeating each field separately. */
        /* 8-byte boundary */
        guint16 hyperlink_length;       /* make sure it fits VTE_HYPERLINK_TOTAL_LENGTH_MAX */
} VteStreamCellAttr;
G_STATIC_ASSERT (sizeof (VteStreamCellAttr) == 10);
G_STATIC_ASSERT (offsetof (VteStreamCellAttr, hyperlink_length) == VTE_CELL_ATTR_COMMON_BYTES);

/*
 * VteCell: A single cell's data
 */

typedef struct _VTE_GNUC_PACKED _VteCell {
	vteunistr c;
	VteCellAttr attr;
} VteCell;
G_STATIC_ASSERT (sizeof (VteCell) == 20);

static const VteCell basic_cell = {
	0,
	{
		0, /* fragment */
		1, /* columns */
		0, /* bold */
		0, /* italic */
		VTE_DEFAULT_FG, /* fore */
		VTE_DEFAULT_BG, /* back */

		0, /* underline */
		0, /* strikethrough */

		0, /* reverse */
		0, /* blink */
		0, /* half */

                0, /* invisible */
                0, /* padding_unused_1 */
                0, /* hyperlink_idx */
                0, /* padding_unused_2 */
	}
};


/*
 * VteRowAttr: A single row's attributes
 */

typedef struct _VteRowAttr {
	guint8 soft_wrapped: 1;
} VteRowAttr;
G_STATIC_ASSERT (sizeof (VteRowAttr) == 1);

/*
 * VteRowData: A single row's data
 */

typedef struct _VteRowData {
	VteCell *cells;
	guint16 len;
	VteRowAttr attr;
} VteRowData;


#define _vte_row_data_length(__row)			((__row)->len + 0)

static inline const VteCell *
_vte_row_data_get (const VteRowData *row, gulong col)
{
	if (G_UNLIKELY (row->len <= col))
		return NULL;

	return &row->cells[col];
}

static inline VteCell *
_vte_row_data_get_writable (VteRowData *row, gulong col)
{
	if (G_UNLIKELY (row->len <= col))
		return NULL;

	return &row->cells[col];
}

/*
 * Copy the common attributes from VteCellAttr to VteStreamCellAttr or vice versa.
 */
static inline void
_attrcpy (void *dst, void *src)
{
        memcpy(dst, src, VTE_CELL_ATTR_COMMON_BYTES);
}

void _vte_row_data_init (VteRowData *row);
void _vte_row_data_clear (VteRowData *row);
void _vte_row_data_fini (VteRowData *row);
void _vte_row_data_insert (VteRowData *row, gulong col, const VteCell *cell);
void _vte_row_data_append (VteRowData *row, const VteCell *cell);
void _vte_row_data_remove (VteRowData *row, gulong col);
void _vte_row_data_fill (VteRowData *row, const VteCell *cell, gulong len);
void _vte_row_data_shrink (VteRowData *row, gulong max_len);


G_END_DECLS

#endif
