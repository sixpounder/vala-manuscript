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

    secondary_text = _("Closing this window will result in a loss of all unsaved changes. It is strongly suggested to save your changes before quitting the application.");

    add_button (_("Keep editing"), 0);

    var close_button = add_button (_("Close this window"), 1);

    close_button.get_style_context().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
  }
}
