namespace Manuscript.Services {
    public class DocumentManager : Object {

        private static DocumentManager instance;

        public static DocumentManager get_default () {
            if (DocumentManager.instance == null) {
                DocumentManager.instance = new DocumentManager ();
            }

            return instance;
        }

        public signal void change ();

        public Services.AppSettings settings { get; private set; }
        public Models.Document document { get; private set; }

        construct {
            settings = Services.AppSettings.get_default ();
        }

        public void set_current_document (Models.Document? doc) {
            if (document != null && document != doc) {
                document = doc;
                settings.last_opened_document = document.file_path;
                change ();
            } else {
                document = null;
            }
        }
    }
}
