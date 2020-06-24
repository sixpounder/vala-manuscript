namespace Manuscript.Widgets {
    public class SourceListCategoryItem: Granite.Widgets.SourceList.ExpandableItem, Granite.Widgets.SourceListSortable {
        public SourceListCategoryItem (string name = "") {
            base(name);
        }

        private bool allow_dnd_sorting () {
            return true;
        }

        private int compare (Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b) {
            // Allow undefined ordering, this will be handled by document model
            return 0;
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
