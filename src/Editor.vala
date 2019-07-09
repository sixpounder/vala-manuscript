public class Editor : Gtk.Box {
  public Document document { get; construct; }
  public Gtk.TextView text_view;

  public bool has_changes { get; private set; }

  protected Stack changes = new Stack<DocumentChange>(false);

  protected AppSettings settings = AppSettings.get_instance();

  public Editor (Document document) {
    Object(
      orientation: Gtk.Orientation.VERTICAL,
      document: document
    );

    if (this.document != null) {
      try {
        this.init_editor();
      } catch (GLib.Error err) {
        // Handle this
      }
    }
  }

  protected void init_editor () throws GLib.Error {
    this.text_view = new Gtk.TextView();
    Gtk.CssProvider provider = new Gtk.CssProvider();
    provider.load_from_data(
      """textview {
        font: 18px iA Writer Duospace;
        color: #333;
      }"""
    );
    this.text_view.get_style_context().add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    this.text_view.pixels_below_lines = 0;
    this.text_view.right_margin = 100;
    this.text_view.left_margin = 100;
    this.text_view.top_margin = 50;
    this.text_view.bottom_margin = 50;
    this.text_view.wrap_mode = Gtk.WrapMode.WORD;
    this.text_view.input_hints = Gtk.InputHints.SPELLCHECK | Gtk.InputHints.NO_EMOJI;
    this.text_view.buffer = this.document.text_buffer;

    Gtk.ScrolledWindow scrollContainer = new Gtk.ScrolledWindow(null, null);
    scrollContainer.add(this.text_view);

    this.settings.last_opened_document = this.document.file_path;

    this.document.change.connect(this.on_document_change);

    this.document.saved.connect(this.on_document_saved);

    this.pack_start(scrollContainer);
  }

  protected void on_document_change () {
    this.has_changes = true;
  }

  protected void on_document_saved (string to_path) {
    this.has_changes = false;
  }
}
