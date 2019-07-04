public class WelcomeView : Gtk.Grid {
  public signal void should_open_file ();

  construct {
    var welcome = new Granite.Widgets.Welcome ("Welcome to Write", "Distraction free writing environment");
    welcome.append ("document-new", "New document", "Create a new empty document");
    welcome.append ("document-open", "Open", "Open an existing document");

    add (welcome);

    welcome.activated.connect ((index) => {
      switch (index) {
        case 0:
          try {
            AppInfo.launch_default_for_uri ("https://valadoc.org/granite/Granite.html", null);
          } catch (Error e) {
            warning (e.message);
          }

          break;
        case 1:
          this.should_open_file();
          break;
      }
    });
  }
}