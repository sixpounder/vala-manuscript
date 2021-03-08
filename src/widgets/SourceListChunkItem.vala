namespace Manuscript.Widgets {
    public class SourceListChunkItem : Granite.Widgets.SourceList.Item, Granite.Widgets.SourceListDragSource {
        public signal void item_should_be_deleted (SourceListChunkItem item);
        protected Models.DocumentChunk _chunk;
        protected Gtk.Menu? item_menu;

        public SourceListChunkItem.with_chunk (Models.DocumentChunk chunk) {
            Object (
                chunk: chunk,
                editable: true,
                selectable: true,
                name: chunk.title
            );
        }

        construct {
            item_menu = new Gtk.Menu ();
            var delete_menu_entry = new Gtk.MenuItem.with_label (_("Remove"));
            delete_menu_entry.activate.connect (() => {
                item_should_be_deleted (this);
            });
            item_menu.append (delete_menu_entry);
            item_menu.show_all ();
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

        public bool has_changes {
            get {
                return chunk.has_changes;
            }
        }

        private void on_edited (string new_name) {
            chunk.title = new_name;
        }

        public override Gtk.Menu? get_context_menu () {
            return item_menu;
        }

        // Drag interface

        public bool draggable () {
            return true;
        }

        public void prepare_selection_data (Gtk.SelectionData selection_data) {
            debug (selection_data.get_text ());
        }
    }
}
