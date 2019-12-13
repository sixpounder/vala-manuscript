public class WelcomeView : Gtk.Grid {
  public signal void should_open_file ();
  public signal void should_create_new_file ();

  construct {
    var welcome = new Granite.Widgets.Welcome ("Welcome to " + Constants.APP_NAME, "Distraction free writing environment");
    welcome.append ("document-new", "New document", "Create a new empty document");
    welcome.append ("document-open", "Open", "Open an existing document");

    add (welcome);

    welcome.activated.connect ((index) => {
      switch (index) {
        case 0:
          this.should_create_new_file();
          break;
        case 1:
          this.should_open_file();
          break;
      }
    });
  }
}

