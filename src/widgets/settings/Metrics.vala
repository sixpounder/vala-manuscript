namespace Manuscript.Widgets.Settings {
    public class DocumentMetricsView : Gtk.Grid {
        public Manuscript.Window parent_window { get; construct; }
        public Services.DocumentManager document_manager { get; private set; }
        public Gtk.SpinButton paragraph_spacing_input { get; set; }

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
            Gtk.Label paragraph_spacing_label = new Gtk.Label (_("Paragraph spacing"));
            paragraph_spacing_input = new Gtk.SpinButton.with_range (0, 1000, 1);
            paragraph_spacing_input.value = 10;
            attach (paragraph_spacing_label, 0, 0, 1, 1);
            attach (paragraph_spacing_input, 1, 0, 1, 1);

            document_manager = parent_window.document_manager;

            if (document_manager.has_document) {
                load_document_settings (document_manager.document);
            }

            document_manager.load.connect (load_document_settings);
        }

        ~DocumentMetricsView () {
            document_manager.load.disconnect (load_document_settings);
        }

        public void load_document_settings (Models.Document document) {
        }
    }
}
