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

        public Models.Document document { get; private set; }

        public void @set (Models.Document? doc) {
            if (document != null && document != doc) {
                document = doc;
                change ();
            } else {
                document = null;
            }
        }
    }
}
