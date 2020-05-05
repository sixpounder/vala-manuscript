namespace Manuscript.Dialogs {
    public class GenericDialog : Gtk.Dialog {
        public Gtk.Widget content_view { get; construct; }
        public Manuscript.Window parent_window { get; construct; }

        public GenericDialog (Manuscript.Window parent_window, Gtk.Widget content_view) {
            Object (
                parent_window: parent_window,
                content_view: content_view,
                modal: false,
                transient_for: parent_window
            );
        }

        construct {
            get_content_area ().pack_start (content_view);
        }
    }
}
