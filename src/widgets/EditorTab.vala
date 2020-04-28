namespace Manuscript {
    public class EditorTab: Granite.Widgets.Tab {
        public Editor editor { get; private set; }
        public weak Models.DocumentChunk chunk { get; construct; }

        public EditorTab (Models.DocumentChunk chunk) {
            Object (
                chunk: chunk,
                label: chunk.title
            );
            var scrolled_container = new Widgets.EditorPage (chunk);
            scrolled_container.editor = new Editor ();
            scrolled_container.editor.chunk = chunk;
            scrolled_container.add (editor);

            page = scrolled_container;
        }
    }
}
