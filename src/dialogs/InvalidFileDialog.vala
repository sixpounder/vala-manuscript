namespace Manuscript {
    public class InvalidFileDialog : Granite.MessageDialog {
        public InvalidFileDialog (Gtk.ApplicationWindow parent) {
            Object (
                buttons: Gtk.ButtonsType.CLOSE,
                transient_for: parent
            );

            set_modal (true);

            image_icon = new ThemedIcon ("dialog-error");

            primary_text = _("Cannot read this manuscript");

            secondary_text = _("The file you selected does not appear to be a valid Manuscript file");
        }
    }
}

