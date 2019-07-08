public class Write : Gtk.Application {
  private AppSettings settings = AppSettings.get_instance();
  public Write () {
    Object (
      application_id: "com.github.sixpounder.write",
      flags: ApplicationFlags.FLAGS_NONE
    );
  }

  protected override void activate () {
    var main_window = new MainWindow (this);

    int x = settings.window_x;
    int y = settings.window_y;
    if (settings.window_width != -1 || settings.window_height != -1) {
      debug (@"Initializing with size $(settings.window_width)x$(settings.window_height)");
      var rect = Gtk.Allocation ();
      rect.height = settings.window_height;
      rect.width = settings.window_width;
      main_window.resize(rect.width, rect.height);
    }

    if (x != -1 && y != -1) {
      debug (@"Initializing at $(x) $(y)");
      main_window.move (x, y);
    }

    main_window.title = "Write";
    main_window.show_all ();
  }

  public static int main (string[] args) {
    var app = new Write ();
    return app.run (args);
  }
}