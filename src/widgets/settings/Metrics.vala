namespace Manuscript.Widgets.Settings {
    public class DocumentMetricsView : Gtk.Grid {
        public Manuscript.Window parent_window { get; construct; }
        public Services.DocumentManager document_manager { get; private set; }
        public Gtk.SpinButton paragraph_spacing_input { get; set; }
        public Gtk.SpinButton paragraph_start_padding_input { get; set; }
        public Gtk.FontButton font_button { get; set; }

        public DocumentMetricsView (Manuscript.Window parent_window) {
            Object (
                parent_window: parent_window,
                expand: true,
                halign: Gtk.Align.CENTER,
                valign: Gtk.Align.START,
                column_spacing: 10,
                row_spacing: 10
            );
        }

        construct {
            document_manager = parent_window.document_manager;

            Gtk.Label font_label = new Gtk.Label (_("Font"));
            font_label.halign = Gtk.Align.END;
            font_button = new Gtk.FontButton.with_font (
                document_manager.document.settings.font != null ? document_manager.document.settings.font : Constants.DEFAULT_FONT
            );
            font_button.use_font = true;
            font_button.show_size = true;
            font_button.show_style = true;
            font_button.font_set.connect (() => {
                var font = font_button.font_desc;
                debug (@"$(font.get_family ()) $(font.get_size ()) $(font.get_size_is_absolute ())");
                document_manager.document.settings.font = @"$(font_button.font_desc.get_family ()) $(font_button.font_desc.get_size () / 1000)";
            });
            attach (font_label, 0, 0, 1, 1);
            attach (font_button, 1, 0, 1, 1);

            Gtk.Label paragraph_spacing_label = new Gtk.Label (_("Paragraph spacing"));
            paragraph_spacing_label.halign = Gtk.Align.END;
            paragraph_spacing_input = new Gtk.SpinButton.with_range (0, 1000, 1);
            paragraph_spacing_input.value = 10;
            paragraph_spacing_input.value_changed.connect (() => {
                if (document_manager.has_document) {
                    document_manager.document.settings.paragraph_spacing = paragraph_spacing_input.value;
                }
            });
            attach (paragraph_spacing_label, 0, 1, 1, 1);
            attach (paragraph_spacing_input, 1, 1, 1, 1);

            if (document_manager.has_document) {
                load_document_settings (document_manager.document);
            }

            Gtk.Label paragraph_start_padding_label = new Gtk.Label (_("Paragraph initial padding"));
            paragraph_start_padding_label.halign = Gtk.Align.END;
            paragraph_start_padding_input = new Gtk.SpinButton.with_range (0, 1000, 1);
            paragraph_start_padding_input.value = 10;
            paragraph_start_padding_input.value_changed.connect (() => {
                if (document_manager.has_document) {
                    document_manager.document.settings.paragraph_start_padding = paragraph_start_padding_input.value;
                }
            });
            attach (paragraph_start_padding_label, 0, 2, 1, 1);
            attach (paragraph_start_padding_input, 1, 2, 1, 1);

            document_manager.load.connect (load_document_settings);
        }

        ~DocumentMetricsView () {
            document_manager.load.disconnect (load_document_settings);
        }

        public void load_document_settings (Models.Document document) {
            font_button.font = document.settings.font;
            paragraph_spacing_input.value = document.settings.paragraph_spacing;
            paragraph_start_padding_input.value = document.settings.paragraph_start_padding;
        }
    }
}
