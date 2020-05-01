namespace Manuscript.Widgets {
    public class SourceListChunkItem : Granite.Widgets.SourceList.Item, Granite.Widgets.SourceListDragDest {
        protected Models.DocumentChunk _chunk;

        public SourceListChunkItem.with_chunk (Models.DocumentChunk chunk) {
            Object (
                chunk: chunk,
                editable: true,
                selectable: true
            );
        }

        construct {
            edited.connect (on_edited);
        }

        ~ SourceListChunkItem () {
            edited.disconnect (on_edited);
        }

        public Models.DocumentChunk chunk {
            get {
                return _chunk;
            }
            set {
                _chunk = value;
                name = chunk.title;
            }
        }

        private void on_edited (string new_name) {
            chunk.title = new_name;
        }

        // Drag interface

        private bool data_drop_possible (Gdk.DragContext context, Gtk.SelectionData data) {
            critical ("PEIHNJFIEN");
            return data.get_target () == Gdk.Atom.intern_static_string ("text/uri-list");
        }
    
        private Gdk.DragAction data_received (Gdk.DragContext context, Gtk.SelectionData data) {
            debug (data.get_uris ()[0]);
            return Gdk.DragAction.COPY;
        }
    }
}
