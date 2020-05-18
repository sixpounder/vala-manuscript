namespace Manuscript.Widgets {
    public class ScrollProgress : Gtk.DrawingArea {
        public Manuscript.Window parent_window { get; set; }
        public ScrollProgress (Manuscript.Window ? parent_window, double initial_value = 0, double min = 0, double max = 100) {
            Object (
                parent_window: parent_window,
                current_value: initial_value,
                min_value: min,
                max_value: max,
                can_focus: false,
                width_request: 100
            );
        }

        construct {
            draw.connect (draw_callback);
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

        protected void redraw () {
            queue_draw ();
        }

        protected bool draw_callback (Cairo.Context cr) {
            var baseline = (get_allocated_height () / 2);
            var w = get_allocated_width ();
            var pad_left = 10.0;
            var pad_right = 50.0;
            var color = get_style_context ().get_color (Gtk.StateFlags.NORMAL);
            cr.move_to (pad_left, baseline);
            cr.set_source_rgba (color.red, color.green, color.blue, color.alpha);
            cr.set_line_cap (Cairo.LineCap.ROUND);
            cr.set_line_width (10);
            cr.line_to (w - pad_right, baseline);
            cr.stroke ();

            cr.move_to (w - pad_right + 10, baseline + 5);
            cr.set_font_size (14);
            cr.select_font_face ("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
            cr.show_text ("100%");
            //  cr.stroke ();

            return false;
        }
    }
}
