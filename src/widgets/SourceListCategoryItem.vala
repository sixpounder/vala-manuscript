namespace Manuscript.Widgets {
    public class SourceListCategoryItem :
        Granite.Widgets.SourceList.ExpandableItem,
        Granite.Widgets.SourceListSortable {

        public Gee.ArrayList<SourceListChunkItem> child_chunks { get; private set; }
        public Models.ChunkType category_type { get; private set; }
        public weak Services.DocumentManager document_manager { get; set; }

        public SourceListCategoryItem (string name = "", Models.ChunkType category_type) {
            base (name);
            this.category_type = category_type;
        }

        construct {
            child_chunks = new Gee.ArrayList<SourceListChunkItem> ();
            child_added.connect (on_child_added);
            child_removed.connect (on_child_removed);
            user_moved_item.connect (on_child_moved);
        }

        //  private bool allow_dnd_sorting () {
        //      return true;
        //  }

        //  private int compare (Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b) {
        //      // Allow undefined ordering, this will be handled by document model
        //      return 0;
        //  }

        private void on_child_added (Granite.Widgets.SourceList.Item item) {
            var it = item as SourceListChunkItem;
            child_chunks.add (it);
            it.item_should_be_deleted.connect (remove);
        }

        private void on_child_removed (Granite.Widgets.SourceList.Item item) {
            var it = item as SourceListChunkItem;
            document_manager.remove_chunk (it.chunk);
            child_chunks.remove (it);
        }

        private void on_child_moved (Granite.Widgets.SourceList.Item item) {
            assert (item != null);
            if (item != null) {
                debug ("Item moved in list, reflecting changes");
                var entry = item as SourceListChunkItem;
                assert (entry.chunk != null);
                if (entry.chunk != null && entry.chunk.chunk_type == category_type) {
                    var previous = item_before (entry) as SourceListChunkItem;
                    var previous_chunk = previous != null ? previous.chunk : null;
                    document_manager.move_chunk (entry.chunk, previous_chunk);
                } else {
                    warning ("Could not move item (item has no chunk associated)");
                }
            } else {
                warning ("Could not move item (NULL)");
            }
        }

        /**
         * Finds the `Granite.Widgets.SourceList.Item` that lies before `item` (if any)
         */
        public Granite.Widgets.SourceList.Item ? item_before (Granite.Widgets.SourceList.Item item) {
            Granite.Widgets.SourceList.Item found = null;
            if (children.size == 1) {
                found = null;
            } else {
                var iter = children.iterator ();
                Granite.Widgets.SourceList.Item last_checked_item = null;
                while (iter.has_next ()) {
                    iter.next ();
                    var i = iter.@get ();
                    if (i == item) {
                        found = last_checked_item;
                        break;
                    } else {
                        last_checked_item = i;
                        continue;
                    }
                }
            }

            return found;
        }

        public bool allow_dnd_sorting () {
            return true;
        }

        public int compare (Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b) {
            return 0;
        }

        //  private bool data_drop_possible (Gdk.DragContext context, Gtk.SelectionData data) {
        //      return data.get_target () == Gdk.Atom.intern_static_string ("text/uri-list");
        //  }

        //  private Gdk.DragAction data_received (Gdk.DragContext context, Gtk.SelectionData data) {
        //      return Gdk.DragAction.COPY;
        //  }
    }
}
