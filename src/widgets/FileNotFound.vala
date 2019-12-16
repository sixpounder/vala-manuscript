public class FileNotFound : Granite.Widgets.AlertView {
  public FileNotFound () {
    base (
      _("File does not exist"),
      _("This file may have been deleted or moved"),
      "dialog-warning"
    );
  }

  construct {
    action_activated.connect (() => {
      hide_action ();
    });
  }
}
