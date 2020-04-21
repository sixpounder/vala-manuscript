namespace Manuscript {
    public class StatusBar : Gtk.ActionBar {
        private uint _words_count = 0;
        private double _reading_time = 0;
        protected Gtk.Label words_label;
        protected Gtk.Label reading_time_label;
        protected Gtk.Image reading_time_icon;
        protected Document _document;
        public Document document {
            get {
                return this._document;
            }
            set {
                this._document = value;
                if (this._document != null) {
                    this.init ();
                }
            }
        }

        construct {
            this.words_label = new Gtk.Label ("0 " + _("words"));
            this.pack_start (words_label);

            this.reading_time_label = new Gtk.Label ("");
            this.reading_time_label.tooltip_text = _("Estimated reading time");
            this.pack_end (reading_time_label);

            this.reading_time_icon = new Gtk.Image ();
            this.reading_time_icon.gicon = new ThemedIcon ("preferences-system-time");
            this.reading_time_icon.pixel_size = 16;
            this.pack_end (reading_time_icon);

            this.init ();
        }

        protected void init () {
            if (this.document != null) {
                if (this.document.load_state == DocumentLoadState.LOADED) {
                    load_document ();
                } else {
                    this.document.load.connect (load_document);
                }
            }
        }

        public uint words {
            get {
                return _words_count;
            }
            set {
                _words_count = value;
                this.words_label.label = "" + _words_count.to_string () + " " + _("words");
                this.reading_time = this.document != null ? this.document.estimate_reading_time : 0;
            }
        }

        protected void load_document () {
            if (document != null) {
                this.words = this.document.words_count;

                this.document.analyze.connect (() => {
                    this.words = this.document != null ? this.document.words_count : 0;
                });
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

