namespace Manuscript {
    public class FileSaveDialog : Gtk.FileChooserDialog {

        public unowned Document document { get; construct; }

        public FileSaveDialog (Gtk.ApplicationWindow parent, Document document) {
            Object (
                transient_for: parent,
                modal: true,
                do_overwrite_confirmation: true,
                create_folders: true,
                action: Gtk.FileChooserAction.SAVE,
                document: document
            );

        }

        construct {
            set_current_name (document.filename);
            add_button (_("Save document"), Gtk.ResponseType.ACCEPT);
            add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        }
    }
}

