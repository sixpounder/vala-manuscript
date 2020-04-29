namespace Manuscript.Widgets {
    public class Sidebar : Gtk.ScrolledWindow {
        protected Gtk.Box layout;
        protected Services.DocumentManager document_manager;

        public Sidebar () {
            Object (
                width_request: 250,
                hexpand: true,
                vexpand: true
            );

            document_manager = Services.DocumentManager.get_default ();
            document_manager.load.connect (on_document_set);
            document_manager.change.connect (on_document_set);
            document_manager.unload.connect (on_document_unload);

            layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            layout.homogeneous = false;

            //  layout.pack_start (new ChunkPreview (null));

            var library_category = new Granite.Widgets.SourceList.ExpandableItem ("Libraries");
            var store_category = new Granite.Widgets.SourceList.ExpandableItem ("Stores");
            var device_category = new Granite.Widgets.SourceList.ExpandableItem ("Devices");

            var music_item = new Granite.Widgets.SourceList.Item ("Music");

            // "Libraries" will be the parent category of "Music"
            library_category.add (music_item);

            // We plan to add sub-items to the store, so let's use an expandable item
            var my_store_item = new Granite.Widgets.SourceList.ExpandableItem ("My Store");
            store_category.add (my_store_item);

            var my_store_podcast_item = new Granite.Widgets.SourceList.Item ("Podcasts");
            var my_store_music_item = new Granite.Widgets.SourceList.Item ("Music");

            my_store_item.add (my_store_music_item);
            my_store_item.add (my_store_podcast_item);

            var player1_item = new Granite.Widgets.SourceList.Item ("Player 1");
            var player2_item = new Granite.Widgets.SourceList.Item ("Player 2");

            device_category.add (player1_item);
            device_category.add (player2_item);

            var source_list = new Granite.Widgets.SourceList ();

            var root = source_list.root;

            root.add (library_category);
            root.add (store_category);
            root.add (device_category);

            layout.pack_start (source_list);

            add (layout);
        }

        public Models.Document document {
            get {
                return document_manager.document;
            }
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

        public void add_chunk (Models.DocumentChunk chunk, bool active = true) {
            assert (chunk != null);
        }

        public void remove_chunk (Models.DocumentChunk chunk) {
            assert (chunk != null);
        }

        public void select_chunk (Models.DocumentChunk chunk) {
            assert (chunk != null);
        }

        public void update_ui () {}
    }
}
