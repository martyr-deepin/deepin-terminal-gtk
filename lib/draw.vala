/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 4 -*-
 * -*- coding: utf-8 -*-
 *
 * Copyright (C) 2011 ~ 2018 Deepin, Inc.
 *               2011 ~ 2018 Wang Yong
 *
 * Author:     Wang Yong <wangyong@deepin.com>
 * Maintainer: Wang Yong <wangyong@deepin.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using Cairo;

namespace Draw {
    public void draw_surface(Cairo.Context cr, ImageSurface surface, int x = 0, int y = 0, int width=0, int height=0) {
        if (surface != null) {
            cr.set_source_surface(surface, x + int.max(0, (int)(width - surface.get_width() / Utils.get_default_monitor_scale()) / 2),
                                  y + int.max(0, (int)(height - surface.get_height() / Utils.get_default_monitor_scale()) / 2));
            cr.paint_with_alpha(1.0);
        }
    }

    public Pango.Layout create_layout_from_context_for_text(Cairo.Context cr, string text, int font_size, int layout_width,
                                         Pango.Alignment horizontal_alignment = Pango.Alignment.LEFT,
                                         string vertical_align = "middle", int? wrap_width=null) {

        var font_description = new Pango.FontDescription();
        font_description.set_size((int)(font_size * Pango.SCALE));

        var layout = Pango.cairo_create_layout(cr);
        layout.set_font_description(font_description);
        layout.set_markup(text, text.length);
        layout.set_alignment(horizontal_alignment);
        if (wrap_width == null) {
            layout.set_single_paragraph_mode(true);
            layout.set_width(layout_width * Pango.SCALE);
            layout.set_ellipsize(Pango.EllipsizeMode.END);
        } else {
            layout.set_width(wrap_width * Pango.SCALE);
            layout.set_wrap(Pango.WrapMode.WORD);
        }

        return layout;
    }

    public void draw_text(Cairo.Context cr, string text, int x, int y, int width, int height, int size,
                          Pango.Alignment horizontal_alignment=Pango.Alignment.LEFT,
                          string vertical_align = "middle",
                          int? wrap_width=null) {
        cr.save();

        var layout = create_layout_from_context_for_text(cr, text, size, width, horizontal_alignment, vertical_align, wrap_width);

        int text_width, text_height;
        layout.get_pixel_size(out text_width, out text_height);

        int render_y;
        if (vertical_align == "top") {
            render_y = y;
        } else if (vertical_align == "middle") {
            render_y = y + int.max(0, (height - text_height) / 2);
        } else {
            render_y = y + int.max(0, height - text_height);
        }

        cr.move_to(x, render_y);
        Pango.cairo_update_layout(cr, layout);
        Pango.cairo_show_layout(cr, layout);

        cr.restore();
    }

    public void draw_layout(Cairo.Context cr, Pango.Layout layout, int x, int y) {
        cr.move_to(x, y);
        Pango.cairo_update_layout(cr, layout);
        Pango.cairo_show_layout(cr, layout);
    }

    public Pango.Layout create_layout_from_widget_for_text(Gtk.Widget widget, string text, int font_size, int layout_width,
                                         Pango.Alignment horizontal_alignment = Pango.Alignment.LEFT,
                                         string vertical_align = "middle", int? wrap_width=null) {

        var font_description = new Pango.FontDescription();
        font_description.set_size((int)(font_size * Pango.SCALE));

        var layout = widget.create_pango_layout(null);
        layout.set_font_description(font_description);
        layout.set_text(text, text.length);
        layout.set_alignment(horizontal_alignment);
        if (wrap_width == null) {
            layout.set_single_paragraph_mode(true);
            layout.set_width(layout_width * Pango.SCALE);
            layout.set_ellipsize(Pango.EllipsizeMode.END);
        } else {
            layout.set_width(wrap_width * Pango.SCALE);
            layout.set_wrap(Pango.WrapMode.WORD);
        }

        return layout;
    }

    public void get_text_bounding_rect_from_widget(Gtk.Widget widget, string text, int font_size, int layout_width,
                                         out int bounding_width, out int bounding_height,
                                         Pango.Alignment horizontal_alignment = Pango.Alignment.LEFT,
                                         string vertical_align = "middle", int? wrap_width=null) {

        var layout = create_layout_from_widget_for_text(widget, text, font_size, layout_width, horizontal_alignment, vertical_align, wrap_width);

        layout.get_pixel_size(out bounding_width, out bounding_height);
    }

    public void get_text_bounding_rect_from_context(Cairo.Context cr, string text, int font_size, int layout_width,
                                         out int bounding_width, out int bounding_height,
                                         Pango.Alignment horizontal_alignment = Pango.Alignment.LEFT,
                                         string vertical_align = "middle", int? wrap_width=null) {

        var layout = create_layout_from_context_for_text(cr, text, font_size, layout_width, horizontal_alignment, vertical_align, wrap_width);

        layout.get_pixel_size(out bounding_width, out bounding_height);
    }

    public int get_text_render_height(Gtk.Widget widget, string text, int width, int height, int size,
                                      Pango.Alignment horizontal_alignment=Pango.Alignment.LEFT,
                                      string vertical_align = "middle",
                                      int? wrap_width=null) {

        int text_width, text_height;

        get_text_bounding_rect_from_widget(widget, text, size, width, out text_width, out text_height, horizontal_alignment, vertical_align, wrap_width);

        return text_height;
    }

    public int get_text_render_width(Cairo.Context cr, string text, int width, int height, int size,
                                      Pango.Alignment horizontal_alignment=Pango.Alignment.LEFT,
                                      string vertical_align = "middle",
                                      int? wrap_width=null) {

        int text_width, text_height;

        get_text_bounding_rect_from_context(cr, text, size, width, out text_width, out text_height, horizontal_alignment, vertical_align, wrap_width);

        return text_width;
    }

    public void set_context_source_color(Cairo.Context cr, Gdk.RGBA rgba) {
        cr.set_source_rgba(rgba.red, rgba.green, rgba.blue, rgba.alpha);
    }

    public void draw_rectangle(Cairo.Context cr, int x, int y, int w, int h, bool fill=true) {
        cr.rectangle(x, y, w, h);
        if (fill) {
            cr.fill();
        } else {
            cr.stroke();
        }
    }

    public void fill_rounded_rectangle(Context cr, int x, int y, int width, int height, double r) {
        cr.new_sub_path();
        cr.arc(x + width - r, y + r, r, Math.PI * 3 / 2, Math.PI * 2);
        cr.arc(x + width - r, y + height - r, r, 0, Math.PI / 2);
        cr.arc(x + r, y + height - r, r, Math.PI / 2, Math.PI);
        cr.arc(x + r, y + r, r, Math.PI, Math.PI * 3 / 2);
        cr.close_path();

        cr.fill();
    }

    public void stroke_rounded_rectangle(Context cr, int x, int y, int width, int height, double r, Gdk.RGBA frame_color, Gdk.RGBA background_color, int line_width=1) {
        cr.set_source_rgba(frame_color.red, frame_color.green, frame_color.blue, frame_color.alpha);
        Draw.fill_rounded_rectangle(cr, x, y, width, height, r);
        cr.set_source_rgba(background_color.red, background_color.green, background_color.blue, background_color.alpha);
        Draw.fill_rounded_rectangle(cr, x + line_width, y + line_width, width - line_width * 2, height - line_width * 2, r);
    }

    public void draw_search_rectangle(Context cr, int x, int y, int width, int height, double r, bool fill=true) {
        // Top side.
        cr.move_to(x, y);
        cr.line_to(x + width, y);

        // Right side.
        cr.line_to(x + width, y + height);

        // Bottom side.
        cr.line_to(x + r, y + height);

        // Bottom-left corner.
        cr.arc(x + r, y + height - r, r, Math.PI / 2, Math.PI);

        // Left side.
        cr.line_to(x, y);

        // Close path.
        cr.close_path();

        if (fill) {
            cr.fill();
        } else {
            cr.stroke();
        }
    }

    public void draw_radial(Cairo.Context cr, int x, int width, int height, Gdk.RGBA center_color, Gdk.RGBA edge_color) {
        Cairo.Pattern pattern = new Cairo.Pattern.radial(x + width / 2, height, width / 2, x + width / 2, height, 0);
        pattern.add_color_stop_rgba(1, center_color.red, center_color.green, center_color.blue, center_color.alpha);
        pattern.add_color_stop_rgba(0, edge_color.red, edge_color.green, edge_color.blue, edge_color.alpha);
        cr.set_source(pattern);
        cr.paint();
    }

    public void clip_rectangle(Cairo.Context cr, int x, int y, int w, int h) {
         cr.rectangle(x, y, w, h);
         cr.clip();
    }

    public void clip_rounded_rectangle(Context cr, int x, int y, int width, int height, double r) {
        cr.new_sub_path();
        cr.arc(x + width - r, y + r, r, Math.PI * 3 / 2, Math.PI * 2);
        cr.arc(x + width - r, y + height - r, r, 0, Math.PI / 2);
        cr.arc(x + r, y + height - r, r, Math.PI / 2, Math.PI);
        cr.arc(x + r, y + r, r, Math.PI, Math.PI * 3 / 2);
        cr.close_path();

        cr.clip();
    }
}
