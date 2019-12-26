namespace Manuscript {
  public class DocumentsNotebook : Granite.Widgets.DynamicNotebook {

    protected bool _on_viewport = true;
    protected AppSettings settings;

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

    public void add_document (Document doc) {
      DocumentTab new_tab = new DocumentTab (doc);
      insert_tab (new_tab, 0);
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
  }
}

