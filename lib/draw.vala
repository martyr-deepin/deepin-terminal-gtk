using Cairo;

namespace Draw {
    public void draw_surface(Cairo.Context cr, ImageSurface surface, int x = 0, int y = 0, double alpha = 1.0) {
        if (surface != null) {
            cr.set_source_surface(surface, x, y);
            cr.paint_with_alpha(alpha);
        }
    }

    public void draw_text(Gtk.Widget widget, Cairo.Context cr, string text, int x, int y, int width, int height,
                          Pango.Alignment text_align=Pango.Alignment.LEFT) {
        var layout = widget.create_pango_layout(text);
		layout.set_width((int)(width * Pango.SCALE));
		layout.set_height((int)(height * Pango.SCALE));
		layout.set_alignment(text_align);
        
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

	public void draw_rounded_rectangle(Context cr, int x, int y, int width, int height, double r, bool fill=true) {
        // Top side.
        cr.move_to(x + r, y);
        cr.line_to(x + width - r, y);
	    
        // Top-right corner.
        cr.arc(x + width - r, y + r, r, Math.PI * 3 / 2, Math.PI * 2);
	    
        // Right side.
        cr.line_to(x + width, y + height - r);
	    
        // Bottom-right corner.
        cr.arc(x + width - r, y + height - r, r, 0, Math.PI / 2);
	    
        // Bottom side.
        cr.line_to(x + r, y + height);
	    
        // Bottom-left corner.
        cr.arc(x + r, y + height - r, r, Math.PI / 2, Math.PI);
	    
        // Left side.
        cr.line_to(x, y + r);
	    
        // Top-left corner.
        cr.arc(x + r, y + r, r, Math.PI, Math.PI * 3 / 2);
	    
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