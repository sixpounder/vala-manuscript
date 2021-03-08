namespace Manuscript.Dialogs {
    public class ExportDialog : Gtk.Dialog {
        public const int ICON_SIZE = 64;
        public weak Manuscript.Window parent_window { get; construct; }
        public weak Manuscript.Models.Document document { get; construct; }
        public Manuscript.Models.ExportFormat export_format { get; private set; }

        protected Gtk.Button export_button;
        protected Gtk.Button close_button;
        protected Gtk.Box format_selection_grid;
        protected Gtk.Spinner progress_indicator;
        protected Gtk.Widget export_button_label;

        public ExportDialog (Manuscript.Window parent_window, Manuscript.Models.Document document) {
            Object (
                parent_window: parent_window,
                transient_for: parent_window,
                document: document,
                modal: true
            );
        }

        construct {
            export_button = new Gtk.Button.with_label (_("Export"));
            export_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            export_button_label = export_button.get_child ();

            close_button = new Gtk.Button.with_label (_("Cancel"));

            progress_indicator = new Gtk.Spinner ();
            progress_indicator.no_show_all = true;

            add_action_widget (close_button, Gtk.ResponseType.CLOSE);
            add_action_widget (export_button, Gtk.ResponseType.NONE);

            var layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            layout.width_request = 500;
            layout.height_request = 400;

            format_selection_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            format_selection_grid.halign = Gtk.Align.CENTER;
            format_selection_grid.valign = Gtk.Align.CENTER;
            format_selection_grid.homogeneous = true;

            var json_radio = new Gtk.RadioButton (null);
            var json_icon = new Gtk.Image ();
            json_icon.gicon = new ThemedIcon ("text-css");
            json_icon.pixel_size = 64;
            json_radio.image = json_icon;
            json_radio.toggled.connect (() => {
                export_format = Manuscript.Models.ExportFormat.JSON;
            });
            format_selection_grid.pack_start (json_radio);

#if EXPORT_COMPILER_PDF
            var pdf_radio = new Gtk.RadioButton.from_widget (json_radio);
            var pdf_icon = new Gtk.Image ();
            pdf_icon.gicon = new ThemedIcon ("application-pdf");
            pdf_icon.pixel_size = ICON_SIZE;
            pdf_radio.image = pdf_icon;
            pdf_radio.toggled.connect (() => {
                export_format = Manuscript.Models.ExportFormat.PDF;
            });
            format_selection_grid.pack_start (pdf_radio);
#endif

#if EXPORT_COMPILER_MARKDOWN
            var markdown_radio = new Gtk.RadioButton.from_widget (json_radio);
            var markdown_icon = new Gtk.Image ();
            markdown_icon.gicon = new ThemedIcon ("text-markdown");
            markdown_icon.pixel_size = ICON_SIZE;
            markdown_radio.image = markdown_icon;
            markdown_radio.toggled.connect (() => {
                export_format = Manuscript.Models.ExportFormat.MARKDOWN;
            });
            format_selection_grid.pack_start (markdown_radio);
#endif

#if EXPORT_COMPILER_PLAIN
            var plain_radio = new Gtk.RadioButton.from_widget (json_radio);
            var plain_icon = new Gtk.Image ();
            plain_icon.gicon = new ThemedIcon ("text-x-generic");
            plain_icon.pixel_size = ICON_SIZE;
            plain_radio.image = plain_icon;
            plain_radio.toggled.connect (() => {
                export_format = Manuscript.Models.ExportFormat.PLAIN;
            });
            format_selection_grid.pack_start (plain_radio);
#endif

            layout.pack_start (format_selection_grid);

            get_content_area ().add (layout);

            show_all ();
        }

        protected void disable_ui () {
            format_selection_grid.sensitive = false;
            export_button.sensitive = false;
            close_button.sensitive = false;
            export_button.remove (export_button.get_child ());
            export_button.child = progress_indicator;
            progress_indicator.show ();
            progress_indicator.start ();
        }

        protected void enable_ui () {
            format_selection_grid.sensitive = true;
            export_button.sensitive = true;
            close_button.sensitive = true;
            export_button.remove (export_button.get_child ());
            export_button.child = export_button_label;
            progress_indicator.hide ();
            progress_indicator.stop ();
        }

        protected void compile (Manuscript.Models.ExportFormat output_format) {
            response (Gtk.ResponseType.ACCEPT);
        }

        public void start_export () {
            disable_ui ();
#if EXPORT_DEMO_MODE
            Timeout.add (5000, () => {
                response (Gtk.ResponseType.ACCEPT);
                return false;
            });
#else
            compile (export_format);
#endif
        }

        //  ~ ExportDialog () {
        //  }
    }
}
