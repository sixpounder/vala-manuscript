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

            layout.pack_start (new ChunkPreview (null));

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
