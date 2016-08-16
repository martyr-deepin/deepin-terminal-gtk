/* -*- Mode: Vala; indent-tabs-mode: nil; tab-width: 4 -*-
 * -*- coding: utf-8 -*-
 *
 * Copyright (C) 2011 ~ 2016 Deepin, Inc.
 *               2011 ~ 2016 Wang Yong
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

using Gtk;
using Widgets;

namespace Widgets {
    public class AboutDialog : Widgets.Dialog {
        public Gtk.Widget focus_widget;
        
        public AboutDialog(Gtk.Widget widget) {
            window_init_width = 500;
            window_init_height = 320;

            focus_widget = widget;
            
            var overlay = new Gtk.Overlay();

            var close_button = new ImageButton("titlebar_close");
            close_button.margin_top = 3;
            close_button.margin_right = 3;
            close_button.set_halign(Gtk.Align.END);
            
            close_button.button_release_event.connect((b) => {
                    this.destroy();
                    
                    return false;
                });
            
            destroy.connect((w) => {
                    if (focus_widget != null) {
                        focus_widget.grab_focus();
                    }
                });
            
            var button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            button_box.pack_start(close_button, true, true, 0);

            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            box.pack_start(button_box, false, false, 0);
            
            var about_widget = new AboutWidget();
            box.pack_start(about_widget, true, true, 0);

            var event_area = new Widgets.WindowEventArea(this);
            event_area.margin_end = 27;
            
            overlay.add(box);
            overlay.add_overlay(event_area);
            
            add_widget(overlay);
        }
        
        public override void draw_window_below(Cairo.Context cr) {
            Gtk.Allocation window_rect;
            window_frame_box.get_allocation(out window_rect);
            
            cr.set_source_rgba(1, 1, 1, 1);
            Draw.draw_rounded_rectangle(cr, window_frame_margin_start, window_frame_margin_top, window_rect.width, window_rect.height, 5);
        }
    }
}