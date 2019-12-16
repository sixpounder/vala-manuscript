public class SettingsPopover : Gtk.Popover {
  protected Gtk.Box layout;
  protected Gtk.Box theme_layout;

  protected ThemeButton lightThemeButton;
  protected ThemeButton darkThemeButton;

  public SettingsPopover (Gtk.Widget relative_to) {
    Object (
      relative_to: relative_to
    );
  }

  construct {
    set_size_request (256, -1);

    layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 10);
    layout.halign = Gtk.Align.CENTER;
    layout.margin_top = 10;
    layout.margin_bottom = 10;
    layout.homogeneous = true;

    theme_layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);

    darkThemeButton = new ThemeButton("dark");
    lightThemeButton = new ThemeButton("light");

    lightThemeButton.selected.connect (this.on_theme_set);
    darkThemeButton.selected.connect (this.on_theme_set);

    theme_layout.pack_start (lightThemeButton, false, true, 15);
    theme_layout.pack_start (darkThemeButton, false, true, 15);

    layout.pack_start (theme_layout);

    add (layout);
  }

  protected void on_theme_set (string theme) {
    AppSettings settings = AppSettings.get_instance ();
    settings.prefer_dark_style = (theme == "dark");
  }
}
