namespace Manuscript.Widgets {
    public class EditorPage : Gtk.ScrolledWindow {

        public Document document { get; construct; }

        public Editor editor;

        public EditorPage (Document document) {
            Object (
                document: document
            );
        }
    }
}
