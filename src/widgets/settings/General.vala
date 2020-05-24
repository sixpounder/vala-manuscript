namespace Manuscript.Widgets.Settings {
    public class DocumentGeneralSettingsView : Gtk.Grid {
        public weak Manuscript.Window parent_window { get; construct; }
        public weak Services.DocumentManager document_manager { get; private set; }
        public Gtk.Entry title_input { get; private set; }
        public Gtk.Switch autosave_switch { get; private set; }

        public DocumentGeneralSettingsView (Manuscript.Window parent_window) {
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

            Gtk.Label title_label = new Gtk.Label (_("Manuscript title"));
            title_label.halign = Gtk.Align.END;

            title_input = new Gtk.Entry ();
            title_input.expand = true;
            title_input.halign = Gtk.Align.FILL;
            title_input.placeholder_text = _("Type a title for your manuscript");
            title_input.text = document_manager.document.title;
            title_input.changed.connect (() => {
                document_manager.document.title = title_input.text;
            });

            attach (title_label, 0, 0, 1, 1);
            attach (title_input, 1, 0, 1, 1);

            Gtk.Label autosave_label = new Gtk.Label (_("Autosave"));
            autosave_label.halign = Gtk.Align.END;

            autosave_switch = new Gtk.Switch ();
            autosave_switch.expand = false;
            autosave_switch.halign = Gtk.Align.START;

            attach (autosave_label, 0, 1, 1, 1);
            attach (autosave_switch, 1, 1, 1, 1);
        }
    }
}
