public class AppSettings : Object {
  public int window_width { get; set; }
  public int window_height { get; set; }
  public int window_x { get; set; }
  public int window_y { get; set; }
  public string last_opened_document { get; set; }

  private GLib.Settings settings = null;

  private static AppSettings instance = null;

  private AppSettings () {
    this.settings = new GLib.Settings("com.github.sixpounder.write");
    settings.bind("window-width", this, "window_width", GLib.SettingsBindFlags.DEFAULT);
    settings.bind("window-height", this, "window_height", GLib.SettingsBindFlags.DEFAULT);
    settings.bind("window-x", this, "window_x", GLib.SettingsBindFlags.DEFAULT);
    settings.bind("window-y", this, "window_y", GLib.SettingsBindFlags.DEFAULT);
    settings.bind("last-opened-document", this, "last_opened_document", GLib.SettingsBindFlags.DEFAULT);
  }

  public static AppSettings get_instance () {
    if (instance == null) {
      instance = new AppSettings();
    }

    return instance;
  }
}