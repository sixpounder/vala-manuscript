/*
 * Copyright 2021 Andrea Coronese <sixpounder@protonmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Manuscript.Widgets {
    public class ScrollProgress : Gtk.DrawingArea {
        private bool first_run = true;
        public Gdk.RGBA color { get; set; }
        public weak Manuscript.Window parent_window { get; set; }

        public ScrollProgress (
            Manuscript.Window ? parent_window, double initial_value = 0, double min = 0, double max = 100
        ) {
            Object (
                parent_window: parent_window,
                current_value: initial_value,
                min_value: min,
                max_value: max,
                can_focus: false,
                width_request: 150
            );
        }

        construct {
            draw.connect (draw_callback);
        }

        protected double _line_width = 10;
        public double line_width {
            get {
                return _line_width;
            }
            set {
                if (value != _line_width) {
                    _line_width = value;
                    redraw ();
                }
            }
        }

        protected bool _show_label = true;
        public bool show_label {
            get {
                return _show_label;
            }

            set {
                if (value != _show_label) {
                    _show_label = value;
                    redraw ();
                }
            }
        }

        protected double _value;
        public double current_value {
            get {
                return _value;
            }
            set {
                if (_value != value) {
                    _value = value;
                    redraw ();
                }
            }
        }

        protected double _max_value;
        public double max_value {
            get {
                return _max_value;
            }
            set {
                if (value != _max_value) {
                    _max_value = value;
                    redraw ();
                }
            }
        }

        protected double _min_value;
        public double min_value {
            get {
                return _min_value;
            }
            set {
                if (value != _min_value) {
                    _min_value = value;
                    redraw ();
                }
            }
        }

        public double progress {
            get {
                if (max_value - min_value != 0) {
                    return ((current_value - min_value) * 100) / (max_value - min_value);
                } else {
                    return 0;
                }
            }
        }

        protected void redraw () {
            queue_draw ();
        }

        protected bool draw_callback (Cairo.Context cr) {
            if (first_run) {
                color = get_style_context ().get_color (Gtk.StateFlags.BACKDROP | Gtk.StateFlags.ACTIVE);
                first_run = false;
            }
            var baseline = (get_allocated_height () / 2);
            var w = get_allocated_width ();
            var pad_left = 10.0;
            var pad_right = show_label ? 60 : 0;

            var available_len = w - pad_right - pad_left;
            var w_amount_percent = (available_len / 100) * progress;
            var target_len = (available_len / 100) * w_amount_percent;

            cr.move_to (pad_left, baseline);
            cr.set_source_rgba (color.red, color.green, color.blue, color.alpha);
            cr.set_line_cap (Cairo.LineCap.ROUND);
            cr.set_line_width (line_width);
            cr.line_to (target_len + pad_left, baseline);
            cr.stroke ();

            if (show_label) {
                cr.move_to (w - pad_right, baseline + 5);
                cr.set_font_size (16);
                cr.select_font_face ("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
                cr.show_text (@"$(Math.ceil (progress).to_string ())%");
            }

            return false;
        }
    }
}
