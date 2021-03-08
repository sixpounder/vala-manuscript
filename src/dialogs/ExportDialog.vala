namespace Manuscript.Dialogs {
    public class ExportDialog : Gtk.Dialog {
        public weak Manuscript.Window parent_window { get; construct; }
        public weak Manuscript.Models.Document document { get; construct; }
        public Manuscript.Models.ExportFormat export_format { get; private set; }

        protected Gtk.Button confirm_btn;
        protected Gtk.Button cancel_btn;
        protected Gtk.Box format_selection_grid;

        public ExportDialog (Manuscript.Window parent_window, Manuscript.Models.Document document) {
            Object (
                parent_window: parent_window,
                transient_for: parent_window,
                document: document,
                modal: true
            );
        }

        construct {
            confirm_btn = new Gtk.Button.with_label (_("Export"));
            confirm_btn.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            confirm_btn.activate.connect (on_confirm);

            cancel_btn = new Gtk.Button.with_label (_("Cancel"));

            add_action_widget (cancel_btn, Gtk.ResponseType.CLOSE);
            add_action_widget (confirm_btn, Gtk.ResponseType.NONE);

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
            pdf_icon.pixel_size = 64;
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
            markdown_icon.pixel_size = 64;
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
            plain_icon.pixel_size = 64;
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
            confirm_btn.sensitive = false;
            confirm_btn.visible = false;
            cancel_btn.sensitive = false;
            cancel_btn.visible = false;
        }

        protected void enable_ui () {
            confirm_btn.sensitive = true;
            confirm_btn.visible = true;
            cancel_btn.sensitive = true;
            cancel_btn.visible = true;
        }

        protected void on_confirm () {
            disable_ui ();
            compile (export_format);
        }

        protected void compile (Manuscript.Models.ExportFormat output_format) {

        }
    }
}
