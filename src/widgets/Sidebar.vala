namespace Manuscript.Widgets {

    public interface SidebarListEntry : Granite.Widgets.SourceList.Item {}

    public class Sidebar : Gtk.Box {
        protected DocumentSourceList root_list;
        protected SourceListCategoryItem chapters_root;
        protected SourceListCategoryItem characters_root;
        protected SourceListCategoryItem notes_root;

        public weak Services.DocumentManager document_manager { get; private set; }
        public weak Manuscript.Window parent_window { get; construct; }

        public Sidebar (Manuscript.Window parent) {
            Object (
                orientation: Gtk.Orientation.VERTICAL,
                width_request: 250,
                hexpand: true,
                vexpand: true,
                parent_window: parent
            );
        }

        construct {
            document_manager = ((Manuscript.Window) parent_window).document_manager;
            document_manager.load.connect (on_document_set);
            document_manager.change.connect (on_document_set);
            document_manager.unload.connect (on_document_unload);
            document_manager.start_editing.connect (on_start_edit);
            document_manager.selected.connect (on_start_edit);

            build_ui ();
        }

        ~ Sidebar () {
            document_manager.load.disconnect (on_document_set);
            document_manager.change.disconnect (on_document_set);
            document_manager.unload.disconnect (on_document_unload);
            document_manager.start_editing.disconnect (on_start_edit);
            document_manager.selected.disconnect (on_start_edit);
            //  chapters_root.user_moved_item.disconnect(on_entry_moved);
            //  characters_root.user_moved_item.disconnect(on_entry_moved);
            //  notes_root.user_moved_item.disconnect(on_entry_moved);
        }

        public Models.Document document {
            get {
                return document_manager.document;
            }
        }

        private void build_ui () {
            // One expandable items per category
            chapters_root = new SourceListCategoryItem (_("Chapters"), Models.ChunkType.CHAPTER);
            chapters_root.document_manager = document_manager;
            characters_root = new SourceListCategoryItem ("Characters sheets", Models.ChunkType.CHARACTER_SHEET);
            characters_root.document_manager = document_manager;
            notes_root = new SourceListCategoryItem (_("Notes"), Models.ChunkType.NOTE);
            notes_root.document_manager = document_manager;

            //  chapters_root.user_moved_item.connect(on_entry_moved);
            //  characters_root.user_moved_item.connect(on_entry_moved);
            //  notes_root.user_moved_item.connect(on_entry_moved);

            root_list = new DocumentSourceList ();

            var root = root_list.root;

            root.add (chapters_root);
            root.add (characters_root);
            root.add (notes_root);

            if (document != null) {
                update_ui ();
            }

            root_list.item_selected.connect (on_item_selected);

            pack_start (root_list);

            reset_tree (document);

            show_all ();
        }

        private void update_ui () {

        }

        public void reset_tree (Models.Document? doc = null) {
            chapters_root.clear ();
            characters_root.clear ();
            notes_root.clear ();
            if (doc != null) {
                var it = doc.chunks.iterator ();
                while (it.next ()) {
                    var item = it.@get ();
                    debug (@"Adding $(item.title)");
                    add_chunk (item, false);
                }
                chapters_root.expand_all ();
                characters_root.expand_all ();
                notes_root.expand_all ();
            }
        }

        private void on_document_set (Models.Document doc) {
            assert (doc != null);
            reset_tree (doc);
            doc.chunk_added.connect (add_chunk);
            doc.chunk_removed.connect (remove_chunk);
            doc.active_changed.connect (select_chunk);
        }

        private void on_document_unload (Models.Document doc) {
            assert (doc != null);
            reset_tree ();
            doc.chunk_added.disconnect (add_chunk);
            doc.chunk_removed.disconnect (remove_chunk);
            doc.active_changed.disconnect (select_chunk);
        }

        private void on_item_selected (Granite.Widgets.SourceList.Item? item) {
            if (item != null && item is SourceListChunkItem) {
                select_chunk (((SourceListChunkItem) item).chunk);
            }
        }

        public SourceListChunkItem? find_node (Models.DocumentChunk chunk) {
            assert (chunk != null);
            Granite.Widgets.SourceList.ExpandableItem root_node;
            switch (chunk.chunk_type) {
                case Models.ChunkType.CHAPTER:
                    root_node = chapters_root;
                    break;
                case Models.ChunkType.CHARACTER_SHEET:
                    root_node = characters_root;
                    break;
                case Models.ChunkType.COVER:
                    root_node = chapters_root;
                    break;
                case Models.ChunkType.NOTE:
                    root_node = notes_root;
                    break;
                default:
                    assert_not_reached ();
            }

            var it = root_node.children.iterator ();
            SourceListChunkItem found_item = null;
            while (it.next ()) {
                SourceListChunkItem item = it.@get () as SourceListChunkItem;
                if (item.chunk == chunk) {
                    found_item = item;
                    break;
                }
            }

            return found_item;
        }

        public void add_chunk (Models.DocumentChunk chunk, bool active = true) {
            assert (chunk != null);
            SourceListChunkItem item_to_add = new SourceListChunkItem.with_chunk (chunk);
            Granite.Widgets.SourceList.ExpandableItem root_node;
            switch (chunk.chunk_type) {
                case Models.ChunkType.CHAPTER:
                    root_node = chapters_root;
                    break;
                case Models.ChunkType.CHARACTER_SHEET:
                    root_node = characters_root;
                    break;
                case Models.ChunkType.NOTE:
                    root_node = notes_root;
                    break;
                default:
                    assert_not_reached ();
            }

            root_node.add (item_to_add);

            if (active) {
                root_list.scroll_to_item (item_to_add);
                root_list.start_editing_item (item_to_add);
            }
        }

        public void remove_chunk (Models.DocumentChunk chunk) {
            assert (chunk != null);
            update_ui ();
        }

        public void select_chunk (Models.DocumentChunk chunk) {
            assert (chunk != null);
            document_manager.open_chunk (chunk);
        }

        public void on_start_edit (Models.DocumentChunk chunk) {
            SourceListChunkItem node = find_node (chunk);
            if (node != null) {
                root_list.selected = node;
                root_list.scroll_to_item (node);
            }
        }
    }
}
