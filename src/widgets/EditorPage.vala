namespace Manuscript.Widgets {
    public class EditorPage : Gtk.ScrolledWindow {

        public Models.DocumentChunk chunk { get; construct; }
        public Editor editor { get; set; }

        public EditorPage (Models.DocumentChunk chunk) {
            Object (
                chunk: chunk
            );
        }
    }
}
