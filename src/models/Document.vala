public class Document : Object {

  public signal void saved (string target_path);
  public signal void load ();
  public signal void change ();
  public signal void undo_queue_drain ();
  public signal void undo ();
  public signal void redo ();
  public signal void analyze ();
  public signal void save_error (Error e);

  protected Gtk.SourceBuffer _buffer;
  protected string _raw_content;

  private ulong buffer_change_handler_id;
  private uint words_counter_timer = 0;

  public uint words_count { get; private set; }
  public double estimate_reading_time { get; private set; }
  public string file_path { get; construct; }
  public bool has_changes { get; private set; }

  public Gtk.SourceBuffer text_buffer {
    get {
      return this._buffer;
    }
  }

  public string text {
    owned get {
      return this.text_buffer != null ? this.text_buffer.text : null;
    }
  }

  protected Document (string? file_path) throws GLib.Error {
    Object(
      file_path: file_path
    );

    if (this.file_path != null) {
      string? content = FileUtils.read (this.file_path);

      if (content != null) {
        this.build_document (content);
      } else {
        this.build_document ("");
      }
    }
  }

  protected void build_document (string content) {
    // this.raw_content = content;
    this._buffer = new Gtk.SourceBuffer (null);
    this._buffer.highlight_matching_brackets = false;
    this._buffer.max_undo_levels = -1;
    this._buffer.set_text (content, content.length);

    this.words_count = Utils.Strings.count_words (this._buffer.text);
    this.estimate_reading_time = Utils.Strings.estimate_reading_time (this.words_count);
    this.buffer_change_handler_id = this._buffer.changed.connect (this.on_content_changed);
    this._buffer.undo.connect(this.on_buffer_undo);
    this._buffer.redo.connect(this.on_buffer_redo);

    this.text_buffer.insert_text.connect (this.text_inserted);
    this.text_buffer.delete_range.connect (this.range_deleted);
    this.text_buffer.undo_manager.can_undo_changed.connect (() => {
      if (this.text_buffer.can_undo) {
        this.has_changes = true;
        this.change ();
      } else {
        this.has_changes = false;
      }
    });

    this.text_buffer.undo_manager.can_redo_changed.connect (() => {
      this.change ();
    });

    this.load ();
  }

  public void save () {
    try {
      FileUtils.save_buffer (this._buffer, this.file_path);
      this.saved (this.file_path);
    } catch (Error e) {
      this.save_error (e);
    }
  }

  public void unload () {
    if (this._buffer != null) {
      this._buffer.disconnect (buffer_change_handler_id);
    }
    this.text_buffer.dispose ();
  }

  /**
   * Emit content_changed event to listeners
   */
  private void on_content_changed () {
    debug ("Changed");
    if (this.words_counter_timer != 0) {
      GLib.Source.remove (this.words_counter_timer);
    }

    // Count words every 200 milliseconds to avoid thrashing the CPU
    this.words_counter_timer = Timeout.add (200, () => {
      this.words_counter_timer = 0;
      this.words_count = Utils.Strings.count_words (this.text_buffer.text);
      this.estimate_reading_time = Utils.Strings.estimate_reading_time (this.words_count);
      this.analyze ();
      return false;
    });

    this.change ();
  }

  private void text_inserted () {}

  private void range_deleted () {}

  private void on_buffer_redo () {
    debug ("Document buffer redo");
    this.redo ();
  }

  private void on_buffer_undo () {
    debug ("Document buffer undo");
    this.undo ();
    if (!this.text_buffer.undo_manager.can_undo ()) {
      debug ("Undo queue drain");
      undo_queue_drain ();
    }
  }

  public static Document from_file (string path) throws GLib.Error {
    return new Document (path);
  }

  public static Document empty () throws GLib.Error {
    return new Document (null);
  }
}
