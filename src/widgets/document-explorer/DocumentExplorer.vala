namespace Manuscript.Widgets {
    public class DocumentExplorer : Gtk.Grid {
        public weak Services.DocumentManager document_manager { get; construct; }
        public weak Manuscript.Window parent_window { get; construct; }

        public DocumentExplorer () {
            Object ();
        }

        construct {
            //  document_manager.load.connect_after (on_document_set);
            //  document_manager.unload.connect_after (on_document_unload);
            //  document_manager.open_chunk.connect_after (on_start_edit);
            //  document_manager.select_chunk.connect_after (on_start_edit);
            //  document_manager.add_chunk.connect_after (on_chunk_added);
        }
    }
}
