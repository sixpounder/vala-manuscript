public class Editor : Gtk.SourceView {
  public bool has_changes { get; private set; }

  protected Gtk.CssProvider provider;
  protected Document _document;
  protected Gtk.SourceLanguageManager manager = Gtk.SourceLanguageManager.get_default ();
  protected AppSettings settings = AppSettings.get_instance ();

  construct {
    try {
      this.init_editor();
      if (document != null) {
        this.document = document;
      }
    } catch (Error e) {
      error("Cannot instantiate editor view: " + e.message);
    }

    settings.change.connect(this.on_setting_change);

    destroy.connect (this.on_destroy);
  }

  public Document document {
    get {
      return this._document;
    }
    set {
      this._document = value;
      this.document.change.connect(this.on_document_change);
      this.document.saved.connect(this.on_document_saved);
      this.load_buffer(this._document.buffer);
    }
  }

  protected void init_editor () throws GLib.Error {

    this.get_style_context().add_provider(get_editor_style (), Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    this.pixels_below_lines = 0;
    this.right_margin = 100;
    this.left_margin = 100;
    this.top_margin = 50;
    this.bottom_margin = 50;
    this.wrap_mode = Gtk.WrapMode.WORD;
    this.input_hints = Gtk.InputHints.SPELLCHECK | Gtk.InputHints.NO_EMOJI;
  }

  protected void load_buffer (Gtk.SourceBuffer newBuffer) {
    buffer = newBuffer;
    buffer.highlight_syntax = true;
    buffer.highlight_matching_brackets = false;
    buffer.language = manager.guess_language (this.document.file_path, null);
    update_settings ();
  }

  protected void update_settings () {
    AppSettings settings = AppSettings.get_instance ();
    if (settings.zen) {
      buffer.notify["cursor-position"].connect (set_focused_paragraph);
    } else {
      buffer.notify["cursor-position"].disconnect (set_focused_paragraph);
    }
  }

  protected void set_focused_paragraph () {
    Gtk.TextIter cursor_iter;
    Gtk.TextIter start, end;

    this.buffer.get_bounds (out start, out end);

    var cursor = this.buffer.get_insert ();
    this.buffer.get_iter_at_mark (out cursor_iter, cursor);

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
