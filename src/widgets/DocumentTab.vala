namespace Manuscript {
    public class DocumentTab: Granite.Widgets.Tab {
        public Editor editor { get; private set; }
        public weak Models.DocumentChunk chunk { get; construct; }

        public DocumentTab (Models.DocumentChunk chunk) {
            Object (
                chunk: chunk,
                label: chunk.title
            );
        }

        construct {
            editor = new Editor ();
            editor.chunk = chunk;

            var scrolled_container = new Gtk.ScrolledWindow (null, null);
            scrolled_container.add (editor);

            page = scrolled_container;
        }
    }
}
