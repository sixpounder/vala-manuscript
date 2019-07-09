public class Header : Gtk.HeaderBar {
  public weak Gtk.Window parent_window { get; construct; }
  public Store store = Store.get_instance();

  public signal void open_file ();

  public Header (Gtk.Window parent) {
    Object(
      title: "Write",
      parent_window: parent,
      has_subtitle: true,
      show_close_button: true
    );

    Gtk.Button open_file_button = new Gtk.Button.from_icon_name("document-open");
    open_file_button.tooltip_text = _("Open file");
    open_file_button.clicked.connect(() => {
      open_file();
    });
    this.pack_start(open_file_button);

    Gtk.Switch zen_switch = new Gtk.Switch();
    zen_switch.set_vexpand(false);
    zen_switch.set_hexpand(false);
    zen_switch.halign = Gtk.Align.CENTER;
    zen_switch.valign = Gtk.Align.CENTER;
    this.pack_end(zen_switch);

    store.switch_document.connect((from, to) => {
      if (to is Document) {
        this.subtitle = to.file_path;
      }
    });

    store.load.connect((document) => {
      if (document is Document) {
        this.subtitle = document.file_path;
      }
    });
  }
}
