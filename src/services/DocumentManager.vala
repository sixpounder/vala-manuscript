namespace Manuscript.Services {
    public class DocumentManager : Object {

        public signal void load (Models.Document document);
        public signal void unload (Models.Document old_document);
        public signal void change (Models.Document new_document);
        public signal void start_editing (Models.DocumentChunk chunk);
        public signal void stop_editing (Models.DocumentChunk chunk);

        private Models.Document _document = null;
        private Gee.ArrayList<Models.DocumentChunk> _opened_chunks;
        public weak Manuscript.Application application { get; construct; }
        public weak Manuscript.Window window { get; construct; }
        public weak Services.AppSettings settings { get; private set; }

        public Models.Document document {
            get {
                return _document;
            }
            private set {
                _document = value;
            }
        }

        public bool has_document {
            get {
                return _document != null;
            }
        }

        public Gee.ArrayList<Models.DocumentChunk> opened_chunks {
            get {
                return _opened_chunks;
            }
        }

        public DocumentManager (Manuscript.Application application, Manuscript.Window window) {
            Object (
                application: application,
                window: window
            );
        }

        construct {
            settings = Services.AppSettings.get_default ();
            _opened_chunks = new Gee.ArrayList<Models.DocumentChunk> ();
        }

        public void set_current_document (owned Models.Document? doc) {
            debug (@"Setting current document: $(doc == null ? "null" : doc.uuid)");
            if (document == null && doc != null) {
                document = doc;
                settings.last_opened_document = document.file_path;
                _opened_chunks.clear ();
                load (document);
            } else if (document != null && document != doc) {
                document = doc;
                settings.last_opened_document = document.file_path;
                _opened_chunks.clear ();
                change (document);
            } else {
                unload (document);
                document = null;
            }
        }

        public void open_chunk (Models.DocumentChunk chunk) {
            if (!opened_chunks.contains (chunk)) {
                opened_chunks.add (chunk);
                start_editing (chunk);
            }
        }

        public void close_chunk (Models.DocumentChunk chunk) {
            if (opened_chunks.contains (chunk)) {
                opened_chunks.remove (chunk);
                stop_editing (chunk);
            }
        }

        // FS ops

        public void save () {
            if (document.temporary) {
                // Ask where to save this
                save_as ();
            } else {
                document.save ();
            }
        }

        public void save_as () {
            var dialog = new FileSaveDialog (window, document);
            int res = dialog.run ();
            if (res == Gtk.ResponseType.ACCEPT) {
                document.save (dialog.get_filename () );
            }
            dialog.destroy ();
        }
    }
}
