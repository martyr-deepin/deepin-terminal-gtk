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

using Animation;
using Gtk;
using Widgets;

namespace Widgets {
    public class Switcher : Gtk.HBox {
        public AnimateTimer scroll_to_left_timer;
        public AnimateTimer scroll_to_right_timer;
        public Gtk.Box box;
        public Gtk.Box left_box;
        public Gtk.Box right_box;
        public Gtk.ScrolledWindow scrolledwindow;
        public int scroll_to_left_end_x;
        public int scroll_to_left_interval = 500;
        public int scroll_to_left_start_x;
        public int scroll_to_right_end_x;
        public int scroll_to_right_interval = 500;
        public int scroll_to_right_start_x;
        public int width;

        public Switcher(int w) {
            width = w;

            scroll_to_left_timer = new AnimateTimer(AnimateTimer.ease_out_quint, scroll_to_left_interval);
            scroll_to_left_timer.animate.connect(scroll_to_left_animate);

            scroll_to_right_timer = new AnimateTimer(AnimateTimer.ease_out_quint, scroll_to_right_interval);
            scroll_to_right_timer.animate.connect(scroll_to_right_animate);

            // NOTE: don's set policy of scrolledwindow to NEVER.
            // Otherwise scrolledwindow will increate width with child's size.
            scrolledwindow = new ScrolledWindow(null, null);
            scrolledwindow.set_shadow_type(Gtk.ShadowType.NONE);
            scrolledwindow.get_style_context().add_class("scrolledwindow");
            scrolledwindow.get_vscrollbar().get_style_context().add_class("switcher_scrollbar");
            scrolledwindow.get_hscrollbar().get_style_context().add_class("switcher_scrollbar");

            box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            left_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            right_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

            set_size_request(width, -1);

            box.pack_start(left_box, false, false, 0);
            box.pack_start(right_box, false, false, 0);
            scrolledwindow.add(box);
            pack_start(scrolledwindow, true, true, 0);
        }

        public void add_to_left_box(Gtk.Widget start_widget) {
            Utils.remove_all_children(left_box);
            Utils.remove_all_children(right_box);

            left_box.pack_start(start_widget, true, true, 0);
        }

        public void scroll_to_left(Gtk.Widget start_widget, Gtk.Widget end_widget) {
            Utils.remove_all_children(left_box);
            Utils.remove_all_children(right_box);

            left_box.pack_start(end_widget, true, true, 0);
            right_box.pack_start(start_widget, true, true, 0);

            var adjust = scrolledwindow.get_hadjustment();
            adjust.set_value(width);

            scroll_to_left_start_x = width;
            scroll_to_left_end_x = 0;

            scroll_to_left_timer.reset();
        }

        public void scroll_to_right(Gtk.Widget start_widget, Gtk.Widget end_widget) {
            Utils.remove_all_children(left_box);
            Utils.remove_all_children(right_box);

            left_box.pack_start(start_widget, true, true, 0);
            right_box.pack_start(end_widget, true, true, 0);

            var adjust = scrolledwindow.get_hadjustment();
            adjust.set_value(0);

            scroll_to_right_start_x = 0;
            scroll_to_right_end_x = width;

            scroll_to_right_timer.reset();
        }

        public void scroll_to_left_animate(double progress) {
            var adjust = scrolledwindow.get_hadjustment();
            adjust.set_value(scroll_to_left_start_x + (int) (scroll_to_left_end_x - scroll_to_left_start_x) * progress);

            if (progress >= 1.0) {
                scroll_to_left_timer.stop();
            }
        }

        public void scroll_to_right_animate(double progress) {
            var adjust = scrolledwindow.get_hadjustment();
            adjust.set_value(scroll_to_right_start_x + (int) (scroll_to_right_end_x - scroll_to_right_start_x) * progress);

            if (progress >= 1.0) {
                scroll_to_right_timer.stop();
            }
        }
    }
}
