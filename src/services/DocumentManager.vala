namespace Manuscript.Services {
  public class DocumentManager : Object {

    public signal void document_added (Document document);
    public signal void document_removed (Document document);

    private static DocumentManager instance;

    public static DocumentManager get_default () {
        if (DocumentManager.instance == null) {
            DocumentManager.instance = new DocumentManager();
        }

        return instance;
    }

    private Gee.ArrayList<Document> _documents;
    public Document[] documents {
      owned get {
          return _documents.to_array ();
      }
    }

    private DocumentManager () {
      _documents = new Gee.ArrayList<Document> ();
    }

    public void add_document (Document document) {
      _documents.add (document);
      document_added (document);
    }

    public void remove_document (Document document) {
      _documents.remove (document);
      document_removed (document);
    }
  }
}

