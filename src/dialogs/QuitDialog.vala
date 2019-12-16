namespace Manuscript {
  public class QuitDialog : Granite.MessageDialog {
    public QuitDialog (EditorWindow parent) {
      Object (
        buttons: Gtk.ButtonsType.NONE,
        transient_for: parent
      );
    }

    construct {
      set_modal (true);

      image_icon = new ThemedIcon ("dialog-warning");

      primary_text = _("Document has unsaved changes");

      secondary_text = _("Leaving now will result in a loss of unsaved changes. It is strongly suggested to save your changes before proceeding.");

      add_button (_("Keep editing"), 0);

      var close_button = add_button (_("Close this document"), 1);

      close_button.get_style_context().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
    }
  }
}

