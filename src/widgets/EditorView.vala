namespace Manuscript {
    public class EditorView: Granite.Widgets.Tab, Protocols.EditorController {
        public Editor editor { get; private set; }
        public weak Models.DocumentChunk chunk { get; construct; }

        public EditorView (Models.DocumentChunk chunk) {
            Object (
                chunk: chunk,
                label: chunk.title
            );
        }

        construct {
            get_style_context ().add_class ("editor-view");
            var scrolled_container = new Gtk.ScrolledWindow (null, null);
            editor = new Editor (chunk);
            scrolled_container.add (editor);
            page = scrolled_container;

            chunk.notify["title"].connect (() => {
                label = chunk.title;
            });
        }

        
        // Editor controller protocol
        public void focus_editor () {
            editor.focus (Gtk.DirectionType.DOWN);
        }

        public bool has_changes () {
            // TODO: return an actually meaningful value
            return false;
        }

        public void on_stats_updated (Protocols.DocumentStats stats) {}
    }
}
