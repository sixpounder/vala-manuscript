namespace Manuscript.Widgets {
    public class QuickOpenEntry: Gtk.Grid {
        public weak Manuscript.Models.DocumentChunk chunk { get; construct; }
        public bool highlighted { get; set; }

        public QuickOpenEntry (Manuscript.Models.DocumentChunk chunk) {
            Object (
                chunk: chunk,
                highlighted: false
            );
        }
    }
}
