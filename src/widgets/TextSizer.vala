public class TextSizer : Gtk.ButtonBox {
  protected Gtk.Button increment_button;
  protected Gtk.Button decrement_button;
  protected Gtk.Label size_label;
  protected AppSettings settings;

  public TextSizer () {
    Object (
      orientation: Gtk.Orientation.HORIZONTAL
    );
  }

  construct {
    settings = AppSettings.get_instance ();
  }

  protected void increment () {}
  protected void decrement () {}
}
