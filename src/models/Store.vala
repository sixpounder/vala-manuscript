public class Store : Object {

  public signal void switch_document (Document from, Document to);
  public signal void load (Document document);

  private Document _current_document = null;
  private static Store instance;

  public Document current_document {
    get {
      return this._current_document;
    }

    set {
      if (this._current_document != null) {
        this._current_document.unload();
      }
      this._current_document = value;
      this.load(this._current_document);
    }
  }

  public Document load_document (string file_path) throws GLib.Error {
    Document target = Document.from_file(file_path);
    this.switch_document(this.current_document, target);
    this.current_document = target;

    return this.current_document;
  }

  construct {
    this.current_document = null;
  }

  protected Store () {
  }

  public static Store get_instance () {
    if (Store.instance == null) {
        Store.instance = new Store();
    }

    return Store.instance;
  }
}