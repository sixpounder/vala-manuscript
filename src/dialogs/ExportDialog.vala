namespace Manuscript.Dialogs {
    public class GenericDialog : Gtk.Dialog {
        public Manuscript.Window parent_window { get; construct; }

        public GenericDialog (Manuscript.Window parent_window) {
            Object (
                parent_window: parent_window,
                transient_for: parent_window,
                modal: true
            );
        }

        construct {
            var layout = new Gtk.Box (Gtk.Orientation.VERTICAL);
            var format_selection_grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
#if EXPORT_COMPILER_PDF
            var pdf_radio = new Gtk.RadioButton.with_label ("PDF");
            format_selection_grid.pack_start (pdf_radio)
#endif

            add (layout);
        }
    }
}
