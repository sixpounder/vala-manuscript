namespace Manuscript.Widgets {
    public class EditorPage : Gtk.ScrolledWindow {

        public Models.Document document { get; construct; }

        public Editor editor;

        public EditorPage (Models.Document document) {
            Object (
                document: document
            );
        }
    }
}
