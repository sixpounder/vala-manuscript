namespace Manuscript.Widgets {
    public class StatusBar : Gtk.ActionBar {
        protected Gtk.Label words_label;
        protected Gtk.Label reading_time_label;
        protected Gtk.Image reading_time_icon;
        protected ScrollProgress scroll_progress_indicator { get; set; }
        
        public weak Manuscript.Window parent_window { get; construct; }
        public weak Models.Document document {
            get {
                return parent_window.document_manager.document;
            }
        }

        public weak Models.DocumentChunk chunk { get; set; }

        public StatusBar (Manuscript.Window parent_window, Models.DocumentChunk chunk) {
            Object (
                parent_window: parent_window,
                chunk: chunk
            );
        }

        construct {
            get_style_context ().add_class ("status-bar");

            words_label = new Gtk.Label ("0 " + _("words"));
            pack_start (words_label);

            scroll_progress_indicator = new Widgets.ScrollProgress (null);
            set_center_widget (scroll_progress_indicator);

            reading_time_label = new Gtk.Label ("");
            reading_time_label.tooltip_text = _("Estimated reading time");
            pack_end (reading_time_label);

            reading_time_icon = new Gtk.Image ();
            reading_time_icon.gicon = new ThemedIcon ("preferences-system-time-symbolic");
            reading_time_icon.pixel_size = 16;
            pack_end (reading_time_icon);

            init ();
        }

        private uint _words_count = 0;
        public uint words {
            get {
                return _words_count;
            }
            set {
                _words_count = value;
                words_label.label = "" + _words_count.to_string () + " " + _("words");
                reading_time = document != null ? document.estimate_reading_time : 0;
            }
        }

        private double _reading_time = 0;
        public double reading_time {
            get {
                return _reading_time;
            }

            set {
                _reading_time = value;
                reading_time_label.label = format_reading_time (_reading_time);
            }
        }

        protected string format_reading_time (double minutes) {
            return minutes <= 1
                ? "< 1 " + _("minute")
                : minutes.to_string () + " " + _("minutes");
        }

        protected void init () {
            if (chunk != null) {
                words = chunk.words_count;
            }
        }

        public void update_scroll_progress (double value, double min, double max) {
            scroll_progress_indicator.current_value = value;
            scroll_progress_indicator.min_value = min;
            scroll_progress_indicator.max_value = max;
        }
    }
}
