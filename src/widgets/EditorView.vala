namespace Manuscript.Widgets{
    public class EditorView: Granite.Widgets.Tab, Protocols.EditorController {
        public Widgets.StatusBar status_bar { get; set; }
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
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            box.expand = true;
            box.homogeneous = false;
            box.halign = Gtk.Align.FILL;
            var scrolled_container = new Gtk.ScrolledWindow (null, null);
            editor = new Editor (chunk);
            status_bar = new Widgets.StatusBar ();
            status_bar.height_request = 50;
            scrolled_container.add (editor);
            box.pack_start (scrolled_container);
            box.pack_start (status_bar, false, true, 0);
            page = box;

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
