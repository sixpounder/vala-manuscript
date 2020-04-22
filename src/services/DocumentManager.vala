namespace Manuscript.Services {
    public class DocumentManager : Object {

        public signal void document_added (Document document, bool active);
        public signal void document_removed (Document document);
        public signal void active_changed (Document document);
        public signal void drain ();

        private static DocumentManager instance;

        public static DocumentManager get_default () {
            if (DocumentManager.instance == null) {
                DocumentManager.instance = new DocumentManager ();
            }

            return instance;
        }

        public Document active_document { get; private set; }

        private Gee.ArrayList<Document> _documents;
        public Document[] documents {
            owned get {
                return _documents.to_array ();
            }
        }

        private DocumentManager () {
            _documents = new Gee.ArrayList<Document> ();
        }

        /**
         * Adds a document to the collection, making it active by default
         */
        public void add_document (Document document, bool activate = true) {
            _documents.add (document);
            document_added (document, activate);
        }

        public void remove_document (Document document) {
            _documents.remove (document);
            document_removed (document);
            if (_documents.size == 0) {
                drain ();
            }
        }

        public void set_active (Document document) {
            if (document != active_document && _documents.contains (document) ) {
                active_document = document;
                active_changed (active_document);
            }
        }
    }
}
