public class Editor : Gtk.SourceView {
  public bool has_changes { get; private set; }

  protected Gtk.CssProvider provider;
  protected Document _document;
  protected AppSettings settings = AppSettings.get_instance ();

  public Editor () {
    Object (
      has_focus: true,
      pixels_inside_wrap: 0,
      pixels_below_lines: 20
    );
  }

  construct {
    try {
      this.init_editor();
      if (document != null) {
        this.document = document;
      }
    } catch (Error e) {
      error("Cannot instantiate editor view: " + e.message);
    }

    settings.change.connect (on_setting_change);

    destroy.connect (on_destroy);
  }

  public Document document {
    get {
      return this._document;
    }
    set {
      _document = value;
      if (_document.loaded) {
        debug ("Loading buffer");
        load_buffer(_document.buffer);
      } else {
        debug ("Waiting for document to become ready");
        _document.load.connect(() => {
          debug ("Loading buffer");
          load_buffer (_document.buffer);
        });
      }
    }
  }

  public void scroll_down () {
    var clock = get_frame_clock ();
    var duration = 200;

    var start = vadjustment.get_value ();
    var end = vadjustment.get_upper () - vadjustment.get_page_size ();
    var start_time = clock.get_frame_time ();
    var end_time = start_time + 1000 * duration;

    add_tick_callback ((widget, frame_clock) => {
      var now = frame_clock.get_frame_time ();
      if (now < end_time && vadjustment.get_value () != end) {
        double t = (now - start_time) / (end_time - start_time);
        t = ease_out_cubic (t);
        vadjustment.set_value (start + t * (end - start));
        return true;
      } else {
        vadjustment.set_value (end);
        return false;
      }
    });
  }

  public bool scroll_to_cursor () {
    scroll_to_mark (buffer.get_insert (), 0.0, true, 0.0, 0.5);
    return settings.zen;
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
    _document.change.connect (this.on_document_change);
    _document.saved.connect (this.on_document_saved);
    update_settings ();
  }

  protected void update_settings () {
    if (buffer != null) {
      AppSettings settings = AppSettings.get_instance ();
      if (settings.zen) {
        set_focused_paragraph ();
        buffer.notify["cursor-position"].connect (set_focused_paragraph);
      } else {
        Gtk.TextIter start, end;
        Gtk.TextTag[] tags = (buffer.tag_table as DocumentTagTable).for_theme (settings.prefer_dark_style ? "dark" : "light");
        buffer.get_bounds (out start, out end);
        buffer.remove_tag (tags[1], start, end);
        buffer.remove_tag (tags[0], start, end);
        buffer.notify["cursor-position"].disconnect (set_focused_paragraph);
      }
    } else {
      warning ("Settings not updated, current buffer is null");
    }
  }

  protected void set_focused_paragraph () {
    Gtk.TextIter cursor_iter;
    Gtk.TextIter start, end;

    buffer.get_bounds (out start, out end);

    var cursor = this.buffer.get_insert ();
    buffer.get_iter_at_mark (out cursor_iter, cursor);

    if (cursor != null) {
      Gtk.TextIter sentence_start = cursor_iter;
      if (cursor_iter != start) {
        sentence_start.backward_sentence_start ();
      }
      Gtk.TextIter sentence_end = cursor_iter;
      if (cursor_iter != end) {
        sentence_end.forward_sentence_end ();
      }

      buffer.remove_tag (buffer.tag_table.lookup("light-focused"), start, end);
      buffer.apply_tag (buffer.tag_table.lookup("light-dimmed"), start, end);
      buffer.apply_tag (buffer.tag_table.lookup("light-focused"), sentence_start, sentence_end);

      scroll_to_cursor ();
    }
  }

  protected void on_setting_change (string key) {
    update_settings ();
  }

  protected void on_document_change () {
    has_changes = true;
  }

  protected void on_document_saved (string to_path) {
    has_changes = false;
  }

  protected void on_destroy () {
    settings.change.disconnect (on_setting_change);
    if (document != null) {
      document.change.disconnect (on_document_change);
      document.saved.disconnect (on_document_saved);
    }
  }
}
