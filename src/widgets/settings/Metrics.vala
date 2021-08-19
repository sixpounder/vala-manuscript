namespace Manuscript.Widgets.Settings {
    public class DocumentMetricsView : Gtk.Grid {
        public Manuscript.Window parent_window { get; construct; }
        public Services.DocumentManager document_manager { get; private set; }

        private Models.PageMargin _page_margin;
        public Models.PageMargin page_margin {
            get {
                return _page_margin;
            }
            set {
                _page_margin = value;
            }
        }

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

        public virtual signal void page_margin_changed (Models.PageMargin size) {
            if (document_manager.has_document) {
                document_manager.document.settings.page_margin = size;
            }
        }

        construct {
            document_manager = parent_window.document_manager;

            Gtk.Label page_margin_label = new Gtk.Label (_("Page margin"));
            page_margin_label.halign = Gtk.Align.START;
            page_margin_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

            Gtk.RadioButton page_margin_small_radio = new Gtk.RadioButton (null);
            var page_margin_small_radio_icon = new Gtk.Image.from_icon_name (
                "document-page-margin-small",
                Gtk.IconSize.LARGE_TOOLBAR
            );
            page_margin_small_radio_icon.pixel_size = 64;
            page_margin_small_radio.image = page_margin_small_radio_icon;

            Gtk.RadioButton page_margin_medium_radio = new Gtk.RadioButton.from_widget (page_margin_small_radio);
            var page_margin_medium_radio_icon = new Gtk.Image.from_icon_name (
                "document-page-margin-medium",
                Gtk.IconSize.LARGE_TOOLBAR
            );
            page_margin_medium_radio_icon.pixel_size = 64;
            page_margin_medium_radio.image = page_margin_medium_radio_icon;

            Gtk.RadioButton page_margin_large_radio = new Gtk.RadioButton.from_widget (page_margin_small_radio);
            var page_margin_large_radio_icon = new Gtk.Image.from_icon_name (
                "document-page-margin-large",
                Gtk.IconSize.LARGE_TOOLBAR
            );
            page_margin_large_radio_icon.pixel_size = 64;
            page_margin_large_radio.image = page_margin_large_radio_icon;

            attach_next_to (page_margin_label, null, Gtk.PositionType.LEFT, 3);
            attach_next_to (page_margin_small_radio, page_margin_label, Gtk.PositionType.BOTTOM, 1);
            attach_next_to (page_margin_medium_radio, page_margin_small_radio, Gtk.PositionType.RIGHT, 1);
            attach_next_to (page_margin_large_radio, page_margin_medium_radio, Gtk.PositionType.RIGHT, 1);

            if (document_manager.has_document) {
                switch (document_manager.document.settings.page_margin) {
                    case Models.PageMargin.SMALL:
                        page_margin_small_radio.active = true;
                        break;
                    case Models.PageMargin.LARGE:
                        page_margin_large_radio.active = true;
                        break;
                    case Models.PageMargin.MEDIUM:
                    default:
                        page_margin_medium_radio.active = true;
                        break;
                }
            }

            page_margin_small_radio.toggled.connect (() => {
                page_margin_changed (Models.PageMargin.SMALL);
            });

            page_margin_medium_radio.toggled.connect (() => {
                page_margin_changed (Models.PageMargin.MEDIUM);
            });

            page_margin_large_radio.toggled.connect (() => {
                page_margin_changed (Models.PageMargin.LARGE);
            });
        }
    }
}
