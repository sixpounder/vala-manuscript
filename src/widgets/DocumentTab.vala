namespace Manuscript {
  public class DocumentTab: Granite.Widgets.Tab {
    public Editor editor { get; private set; }
    public weak Document document { get; construct; }

    public DocumentTab (Document document) {
      Object (
        document: document,
        label: document.filename
      );
    }

    construct {
      editor = new Editor ();
      editor.document = document;

      var scrolled_container = new Gtk.ScrolledWindow (null, null);
      scrolled_container.add (editor);

      page = scrolled_container;
    }
  }
}

