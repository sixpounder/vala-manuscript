namespace Manuscript.Services {
    public class DocumentManager : Object {

        private static DocumentManager instance;
        private Models.Document _document = null;
        private Gee.ArrayList<Models.DocumentChunk> _opened_chunks;

        public static DocumentManager get_default () {
            if (DocumentManager.instance == null) {
                DocumentManager.instance = new DocumentManager ();
            }

            return instance;
        }

        public signal void load (Models.Document document);
        public signal void unload (Models.Document old_document);
        public signal void change (Models.Document new_document);

        public Services.AppSettings settings { get; private set; }
        public Models.Document document {
            get {
                return _document;
            }
            private set {
                _document = value;
            }
        }

        public Gee.ArrayList<Models.DocumentChunk> opened_chunks {
            get {
                return _opened_chunks;
            }
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
                load (document);
            } else if (document != null && document != doc) {
                document = doc;
                settings.last_opened_document = document.file_path;
                change (document);
            } else {
                unload (document);
                document = null;
            }
        }
    }
}
