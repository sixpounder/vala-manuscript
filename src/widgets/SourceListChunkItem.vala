namespace Manuscript.Widgets {
    public class SourceListCategoryItem: Granite.Widgets.SourceList.ExpandableItem, Granite.Widgets.SourceListSortable {
        public Gee.ArrayList<SourceListChunkItem> child_chunks { get; private set; }
        public Models.ChunkType category_type { get; private set; }
        public Services.DocumentManager document_manager { get; set; }

        public SourceListCategoryItem (string name = "", Models.ChunkType category_type) {
            base(name);
            this.category_type = category_type;
        }

        construct {
            child_chunks = new Gee.ArrayList<SourceListChunkItem> ();
            child_added.connect (on_child_added);
            child_removed.connect (on_child_removed);
            user_moved_item.connect (on_child_moved);
        }

        private bool allow_dnd_sorting () {
            return true;
        }

        private int compare (Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b) {
            // Allow undefined ordering, this will be handled by document model
            return 0;
        }

        private void on_child_added (Granite.Widgets.SourceList.Item item) {
            child_chunks.add (item as SourceListChunkItem);
        }

        private void on_child_removed (Granite.Widgets.SourceList.Item item) {
            child_chunks.remove (item as SourceListChunkItem);
        }

        private void on_child_moved (Granite.Widgets.SourceList.Item item) {
            assert (item != null);
            var entry = item as SourceListChunkItem;
            assert (entry.chunk != null);

            if (entry.chunk.chunk_type == category_type) {
                // Same category move
                document_manager.document.move_chunk (entry.chunk, child_chunks.index_of (entry));
            }
        }
    }

    public class SourceListChunkItem : Granite.Widgets.SourceList.Item, Granite.Widgets.SourceListDragSource {
        protected Models.DocumentChunk _chunk;

        public SourceListChunkItem.with_chunk (Models.DocumentChunk chunk) {
            Object (
                chunk: chunk,
                editable: true,
                selectable: true,
                name: chunk.title
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

        public bool has_changes {
            get {
                return chunk.has_changes;
            }
        }

        private void on_edited (string new_name) {
            chunk.title = new_name;
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
