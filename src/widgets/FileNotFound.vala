namespace Manuscript {
  public class FileNotFound : Granite.Widgets.AlertView {
    public string expected_path { get; protected set; }
    public FileNotFound (string expected_path) {
      base (
        _("File does not exist"),
        _("This file may have been deleted or moved.") + "\n" + @"<i>$expected_path</i> " + _("not found"),
        "dialog-warning"
      );

      this.expected_path = expected_path;
    }

    construct {
      action_activated.connect (() => {
        hide_action ();
      });
    }
  }
}

