public class Manuscript : Gtk.Application {
  public Manuscript () {
    Object (
      application_id: Constants.APP_ID,
      flags: ApplicationFlags.FLAGS_NONE
    );
  }

  protected override void activate () {
    var main_window = new MainWindow (this);
    main_window.title = Constants.APP_NAME;
    main_window.show_all ();
  }

  public static int main (string[] args) {
    var app = new Manuscript ();
    return app.run (args);
  }
}

