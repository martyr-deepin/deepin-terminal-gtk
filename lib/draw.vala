using Cairo;

namespace Draw {
    public void draw_surface(Cairo.Context cr, ImageSurface surface, int x = 0, int y = 0, double alpha = 1.0) {
        if (surface != null) {
            cr.set_source_surface(surface, x, y);
            cr.paint_with_alpha(alpha);
        }
    }

    public void draw_text(Gtk.Widget widget, Cairo.Context cr, string text, int x, int y) {
        var layout = widget.create_pango_layout(text);
        draw_layout(cr, layout, x, y);
    }

    public void draw_layout(Cairo.Context cr, Pango.Layout layout, int x, int y) {
        cr.move_to(x, y);
        Pango.cairo_update_layout(cr, layout);
        Pango.cairo_show_layout(cr, layout);
    }

    public void draw_rectangle(Cairo.Context cr, int x, int y, int w, int h, bool fill=true) {
        cr.rectangle(x, y, w, h);
        if (fill) {
            cr.fill();
        } else {
            cr.stroke();
        }
    }

    public void clip_rectangle(Cairo.Context cr, int x, int y, int w, int h) {
         cr.rectangle(x, y, w, h);
         cr.clip();
    }

    public void render_text(Cairo.Context cr, string text, int x, int y, int width, int height,
                            Pango.FontDescription font_description,
                            Pango.Alignment text_align=Pango.Alignment.LEFT) {
		var layout = Pango.cairo_create_layout(cr);
		layout.set_text(text, (int)text.length);
		layout.set_width((int)(width * Pango.SCALE));
		layout.set_height((int)(height * Pango.SCALE));
        layout.set_font_description(font_description);
		layout.set_alignment(text_align);
		
        cr.move_to(x, y);
		Pango.cairo_update_layout(cr, layout);
		Pango.cairo_show_layout(cr, layout);
	}
}