namespace Manuscript {
  public class SettingsPopover : Gtk.Popover {
    protected Gtk.Box layout;
    protected Gtk.Box theme_layout;

    protected ThemeButton light_theme_button;
    protected ThemeButton dark_theme_button;

    public SettingsPopover (Gtk.Widget relative_to) {
      Object (
        relative_to: relative_to
      );
    }

    construct {
      set_size_request (256, -1);

      layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
      layout.halign = Gtk.Align.CENTER;
      layout.margin_top = 10;
      layout.margin_bottom = 10;
      layout.homogeneous = true;

      theme_layout = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);

      dark_theme_button = new ThemeButton ("dark");
      light_theme_button = new ThemeButton ("light");

      light_theme_button.selected.connect (this.on_theme_set);
      dark_theme_button.selected.connect (this.on_theme_set);

      theme_layout.pack_start (light_theme_button, false, true, 15);
      theme_layout.pack_start (dark_theme_button, false, true, 15);

      layout.pack_start (theme_layout);

      add (layout);
    }

    protected void on_theme_set (string theme) {
      AppSettings settings = AppSettings.get_instance ();
      settings.prefer_dark_style = (theme == "dark");
    }
  }
}

