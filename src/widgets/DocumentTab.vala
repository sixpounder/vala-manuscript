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
            var scrolled_container = new Widgets.EditorPage (chunk);
            scrolled_container.editor = new Editor ();
            scrolled_container.editor.chunk = chunk;
            scrolled_container.add (editor);

            page = scrolled_container;
        }
    }
}
