public class Header : Gtk.HeaderBar {
  public weak Gtk.Window parent_window { get; construct; }

  public Header (Gtk.Window parent) {
    Object(
      title: "Write",
      parent_window: parent,
      has_subtitle: true,
      show_close_button: true
    );
  }
}