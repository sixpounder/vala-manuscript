namespace Manuscript {
    public class StatusBar : Gtk.ActionBar {
        private uint _words_count = 0;
        private double _reading_time = 0;
        protected Gtk.Label words_label;
        protected Gtk.Label reading_time_label;
        protected Gtk.Image reading_time_icon;
        protected Models.Document _document;
        public Models.Document document {
            get {
                return _document;
            }
            set {
                _document = value;
                if (_document != null) {
                    init ();
                }
            }
        }

        construct {
            get_style_context ().add_class ("status-bar");

            words_label = new Gtk.Label ("0 " + _("words"));
            pack_start (words_label);

            reading_time_label = new Gtk.Label ("");
            reading_time_label.tooltip_text = _("Estimated reading time");
            pack_end (reading_time_label);

            reading_time_icon = new Gtk.Image ();
            reading_time_icon.gicon = new ThemedIcon ("preferences-system-time");
            reading_time_icon.pixel_size = 16;
            pack_end (reading_time_icon);

            init ();
        }

        protected void init () {
            if (document != null) {
                if (document.load_state == DocumentLoadState.LOADED) {
                    load_document ();
                } else {
                    document.load.connect (load_document);
                }
            }
        }

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

        protected void load_document () {
            if (document != null) {
                words = document.words_count;
            }
        }

        public double reading_time {
            get {
                return _reading_time;
            }

            set {
                _reading_time = value;
                reading_time_label.label = format_reading_time (_reading_time);
            }
        }

        private string format_reading_time (double minutes) {
            return minutes <= 1
                ? "< 1 " + _("minute")
                : minutes.to_string () + " " + _("minutes");
        }
    }
}
