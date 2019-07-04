public class Editor : Gtk.Box {
  public string file_path { get; construct; }
  public string raw { get; set; }
  public Gtk.TextView text_view;
  protected Document document;

  protected AppSettings settings = AppSettings.get_instance();

  public Editor (string file_path) {
    Object(
      orientation: Gtk.Orientation.VERTICAL,
      file_path: file_path
    );

    if (this.file_path != null) {
      try {
        this.init_editor();
      } catch (GLib.Error err) {
        // Handle this
      }
    }
  }

  protected void init_editor () throws GLib.Error {
    this.document = Store.get_instance().load_document(this.file_path);
    this.text_view = new Gtk.TextView();
    Gtk.CssProvider provider = new Gtk.CssProvider();
    provider.load_from_data(
      """textview {
        font: 16px iA Writer Duospace;
        color: #333;
      }"""
    );
    this.text_view.get_style_context().add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    this.text_view.pixels_below_lines = 5;
    this.text_view.wrap_mode = Gtk.WrapMode.WORD;
    this.text_view.input_hints = Gtk.InputHints.SPELLCHECK | Gtk.InputHints.NO_EMOJI;
    this.text_view.buffer = this.document.text_buffer;
    Gtk.ScrolledWindow scrollContainer = new Gtk.ScrolledWindow(null, null);
    scrollContainer.add(this.text_view);
    this.pack_start(scrollContainer);
    this.settings.last_opened_document = this.file_path;
  }
}
