public class Editor : Gtk.Box {
  public Gtk.SourceView text_view;

  public bool has_changes { get; private set; }

  protected Gtk.CssProvider provider;
  protected Document _document;
  protected AppSettings settings = AppSettings.get_instance();

  public Editor (Document document) throws Error {
    Object(
      orientation: Gtk.Orientation.VERTICAL
    );

    this.destroy.connect (this.on_destroy);

    try {
      this.init_editor();
      if (document != null) {
        this.document = document;
      }
    } catch (Error e) {
      error("Cannot instantiate editor view: " + e.message);
    }
  }

  public Document document {
    get {
      return this._document;
    }
    set {
      this._document = value;
      this.document.change.connect(this.on_document_change);
      this.document.saved.connect(this.on_document_saved);
      // this.text_view = new Gtk.SourceView.with_buffer (this._document.text_buffer);
      this.load_buffer(this._document.text_buffer);
      this.settings.last_opened_document = this._document.file_path;
    }
  }

  protected void init_editor () throws GLib.Error {

    this.text_view = new Gtk.SourceView ();
    this.text_view.get_style_context().add_provider(get_editor_style (), Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    this.text_view.pixels_below_lines = 0;
    this.text_view.right_margin = 100;
    this.text_view.left_margin = 100;
    this.text_view.top_margin = 50;
    this.text_view.bottom_margin = 50;
    this.text_view.wrap_mode = Gtk.WrapMode.WORD;
    this.text_view.input_hints = Gtk.InputHints.SPELLCHECK | Gtk.InputHints.NO_EMOJI;

    Gtk.ScrolledWindow scrollContainer = new Gtk.ScrolledWindow(null, null);
    scrollContainer.add(this.text_view);

    this.pack_start(scrollContainer);
  }

  protected void load_buffer (Gtk.SourceBuffer buffer) {
    buffer.begin_not_undoable_action ();
    this.text_view.buffer = buffer;
    buffer.end_not_undoable_action ();
  }

  protected void on_document_change () {
    this.has_changes = true;
  }

  protected void on_document_saved (string to_path) {
    this.has_changes = false;
  }

  protected void on_destroy () {
    if (this.document != null) {
      this.document.change.disconnect (this.on_document_change);
      this.document.saved.disconnect (this.on_document_saved);
    }
  }
}
