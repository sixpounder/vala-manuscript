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

        private void on_child_added (Granite.Widgets.SourceList.Item item) {
            var it = item as SourceListChunkItem;
            child_chunks.add (it);
            it.item_should_be_deleted.connect (remove);
        }

        private void on_child_removed (Granite.Widgets.SourceList.Item item) {
            debug ("Source list removed chunk item");
            var it = item as SourceListChunkItem;
            child_chunks.remove (it);
        }

        private void on_child_moved (Granite.Widgets.SourceList.Item item) {
            assert (item != null);
            if (item != null) {
                debug ("Item moved in list, reflecting changes");
                var entry = item as SourceListChunkItem;
                assert (entry.chunk != null);
                if (entry.chunk != null && entry.chunk.kind == category_type) {
                    var next_item = item_after (entry) as SourceListChunkItem;
                    var next_chunk = next_item != null ? next_item.chunk : null;
                    document_manager.move_chunk (entry.chunk, next_chunk);
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

        /**
         * Finds the `Granite.Widgets.SourceList.Item` that lies after `item` (if any)
         */
         public Granite.Widgets.SourceList.Item ? item_after (Granite.Widgets.SourceList.Item item) {
            Granite.Widgets.SourceList.Item found = null;
            if (children.size == 0) {
                found = null;
            } else {
                var iter = children.iterator ();
                while (iter.has_next ()) {
                    iter.next ();
                    var i = iter.@get ();
                    if (i == item) {
                        // Next item is the item we want to return
                        if (iter.has_next ()) {
                            iter.next ();
                            found = iter.@get ();
                        } else {
                            found = null;
                        }

                        break;
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
    }
}
