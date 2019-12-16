namespace Manuscript {
  public class AppSettings : Object {

    public signal void change (string key);
    public int window_width { get; set; }
    public int window_height { get; set; }
    public int window_x { get; set; }
    public int window_y { get; set; }
    public string last_opened_document { get; set; }
    public bool zen { get; set; }
    public bool prefer_dark_style { get; set; }

    private GLib.Settings settings = null;

    private static AppSettings instance = null;

    private AppSettings () {
      this.settings = new GLib.Settings(Constants.APP_ID);
      settings.bind("window-width", this, "window_width", GLib.SettingsBindFlags.DEFAULT);
      settings.bind("window-height", this, "window_height", GLib.SettingsBindFlags.DEFAULT);
      settings.bind("window-x", this, "window_x", GLib.SettingsBindFlags.DEFAULT);
      settings.bind("window-y", this, "window_y", GLib.SettingsBindFlags.DEFAULT);
      settings.bind("last-opened-document", this, "last_opened_document", GLib.SettingsBindFlags.DEFAULT);
      settings.bind("zen", this, "zen", GLib.SettingsBindFlags.DEFAULT);
      settings.bind("prefer-dark-style", this, "prefer_dark_style", GLib.SettingsBindFlags.DEFAULT);

      settings.changed.connect(this.on_change);
    }

    public static AppSettings get_instance () {
      if (instance == null) {
        instance = new AppSettings();
      }

      return instance;
    }

    protected void on_change (string key) {
      debug (key + " changed");
      this.change (key);
    }
  }
}

