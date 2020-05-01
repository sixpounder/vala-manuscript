namespace Manuscript {
    public class EditorTab: Granite.Widgets.Tab, Protocols.EditorController {
        public Editor editor { get; private set; }
        public weak Models.DocumentChunk chunk { get; construct; }

        public EditorTab (Models.DocumentChunk chunk) {
            Object (
                chunk: chunk,
                label: chunk.title
            );
        }

        construct {
            var scrolled_container = new Gtk.ScrolledWindow (null, null);
            editor = new Editor (chunk);
            scrolled_container.add (editor);
            page = scrolled_container;

            chunk.notify["title"].connect (() => {
                label = chunk.title;
            });
        }

        public void focus_editor () {
            editor.focus (Gtk.DirectionType.DOWN);
        }

        // Editor controller protocol

        public bool has_changes () {
            // TODO: return an actual meaningful value
            return false;
        }
    }
}

