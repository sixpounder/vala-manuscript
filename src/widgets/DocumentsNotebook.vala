namespace Manuscript {
  public class DocumentsNotebook : Granite.Widgets.DynamicNotebook {

    protected bool _on_viewport = true;
    protected AppSettings settings;
    protected Services.DocumentManager documents_manager;

    public bool on_viewport {
      get {
        return _on_viewport;
      }

      set {
        _on_viewport = value;
        var style = get_style_context ();
        style.remove_class ("toggled-on");
        style.remove_class ("toggled-off");

        style.add_class (@"toggled-$(_on_viewport ? "on" : "off")");
      }
    }

    public DocumentsNotebook () {
      Object (
        add_button_visible: true
      );

      documents_manager = Services.DocumentManager.get_default ();

      documents_manager.document_added.connect ((document, active) => {
        this.add_document (document, active);
      });

      documents_manager.document_removed.connect ((document) => {
        this.remove_document (document);
      });

      documents_manager.active_changed.connect ((document) => {
        select_document (document);
      });
    }

    construct {
      get_style_context ().add_class ("documents-notebook");

      settings = AppSettings.get_instance ();
      on_viewport = !settings.zen;

      settings.change.connect ((key) => {
        if (key == "zen") {
          on_viewport = !settings.zen;
        }
      });
    }

    public void add_document (Document doc, bool active = true) {
      DocumentTab new_tab = new DocumentTab (doc);
      insert_tab (new_tab, 0);
      if (active) {
        current = new_tab;
      }
    }

    public void remove_document (Document doc) {
      for (int i = 0; i < tabs.length (); i++) {
        DocumentTab t = (DocumentTab) tabs.nth (i);
        if (t.document == doc) {
          remove_tab (t);
          return;
        }
      }
    }

    public void select_document (Document doc) {
      for (int i = 0; i < tabs.length (); i++) {
        DocumentTab t = (DocumentTab) tabs.nth (i);
        if (t.document != null && t.document == doc) {
          current = t;
          return;
        }
      }
    }
  }
}

