public class Editor : Gtk.Box {
  public Gtk.SourceView text_view;

  public bool has_changes { get; private set; }

  protected Gtk.CssProvider provider;
  protected Document _document;
  protected Gtk.SourceLanguageManager manager = Gtk.SourceLanguageManager.get_default ();
  protected AppSettings settings = AppSettings.get_instance ();

  public Editor (Document document) throws Error {
    Object(
      orientation: Gtk.Orientation.VERTICAL
    );
  }

  construct {
    this.destroy.connect (this.on_destroy);

    try {
      this.init_editor();
      if (document != null) {
        this.document = document;
      }
    } catch (Error e) {
      error("Cannot instantiate editor view: " + e.message);
    }

    settings.change.connect(this.on_setting_change);
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
    buffer.highlight_syntax = true;
    buffer.highlight_matching_brackets = false;
    buffer.language = manager.guess_language (this.document.file_path, null);
    this.text_view.buffer = buffer;
    buffer.end_not_undoable_action ();

    update_settings ();
  }

  protected void update_settings () {
    AppSettings settings = AppSettings.get_instance ();
    if (settings.zen) {
      this.text_view.buffer.notify["cursor-position"].connect (set_focused_paragraph);
      // TODO: add styles
    } else {
      this.text_view.buffer.notify["cursor-position"].disconnect (set_focused_paragraph);
    }
  }

  protected void set_focused_paragraph () {
    Gtk.TextIter cursor_iter;
    Gtk.TextIter start, end;

    this.text_view.buffer.get_bounds (out start, out end);

    var cursor = this.text_view.buffer.get_insert ();
    this.text_view.buffer.get_iter_at_mark (out cursor_iter, cursor);

    if (cursor != null) {
      Gtk.TextIter sentence_start = cursor_iter;
      if (cursor_iter != start) {
        sentence_start.backward_sentence_start ();
      }
      Gtk.TextIter sentence_end = cursor_iter;
      if (cursor_iter != end) {
        sentence_end.forward_sentence_end ();
      }
    }
  }

  protected void on_setting_change (string key) {
    this.update_settings ();
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
