namespace Manuscript.Widgets {

    public interface SidebarListEntry : Granite.Widgets.SourceList.Item {}

    public class Sidebar : Gtk.Box {
        protected Granite.Widgets.SourceList root_list;
        protected Granite.Widgets.SourceList.ExpandableItem chapters_root;
        protected Granite.Widgets.SourceList.ExpandableItem characters_root;
        protected Granite.Widgets.SourceList.ExpandableItem notes_root;

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

            build_ui ();
        }

        public Models.Document document {
            get {
                return document_manager.document;
            }
        }

        private void build_ui () {
            chapters_root = new Granite.Widgets.SourceList.ExpandableItem (_("Chapters"));
            characters_root = new Granite.Widgets.SourceList.ExpandableItem ("Characters sheets");
            notes_root = new Granite.Widgets.SourceList.ExpandableItem (_("Notes"));

            root_list = new Granite.Widgets.SourceList ();

            var root = root_list.root;

            root.add (chapters_root);
            root.add (characters_root);
            root.add (notes_root);

            if (document != null) {
                update_ui ();
            }

            root_list.item_selected.connect (on_item_selected);

            pack_start (root_list);

            Gtk.TargetEntry uri_list_entry = { "text/uri-list", Gtk.TargetFlags.SAME_APP, 0 };
            root_list.enable_drag_dest ({ uri_list_entry }, Gdk.DragAction.COPY);

            show_all ();
        }

        private void update_ui () {

        }

        private void on_document_set (Models.Document doc) {
            assert (doc != null);
            doc.chunk_added.connect (add_chunk);
            doc.chunk_removed.connect (remove_chunk);
            doc.active_changed.connect (select_chunk);
        }

        private void on_document_unload (Models.Document doc) {
            assert (doc != null);
            doc.chunk_added.disconnect (add_chunk);
            doc.chunk_removed.disconnect (remove_chunk);
            doc.active_changed.disconnect (select_chunk);
        }

        private void on_item_selected (Granite.Widgets.SourceList.Item? item) {
            if (item != null && item is SourceListChunkItem) {
                select_chunk ( ((SourceListChunkItem) item).chunk );
            }
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

            root_list.scroll_to_item (item_to_add);
            root_list.start_editing_item (item_to_add);
        }

        public void remove_chunk (Models.DocumentChunk chunk) {
            assert (chunk != null);
            update_ui ();
        }

        public void select_chunk (Models.DocumentChunk chunk) {
            assert (chunk != null);
            document_manager.open_chunk (chunk);
        }
    }
}

