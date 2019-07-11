public class Document : Object {

  public signal void saved (string target_path);
  public signal void load ();
  public signal void change ();
  public signal void analyze ();
  public signal void save_error (Error e);

  protected Gtk.TextBuffer _buffer;
  protected string _raw_content;

  private ulong buffer_change_handler_id;
  private uint words_counter_timer = 0;
  private DocumentChange[] edit_stack;

  public uint words_count { get; private set; }
  public double estimate_reading_time { get; private set; }

  public string file_path { get; construct; }

  public Gtk.TextBuffer text_buffer {
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

    this.build_document (this.file_path != null ? FileUtils.read (this.file_path) : "");
  }

  protected void build_document (string content) {
    // this.raw_content = content;
    this._buffer = new Gtk.TextBuffer (null);
    this._buffer.set_text (content, content.length);
    this.words_count = Utils.Strings.count_words (this._buffer.text);
    this.estimate_reading_time = Utils.Strings.estimate_reading_time (this.words_count);
    this.buffer_change_handler_id = this._buffer.changed.connect (this.on_content_changed);
    this.text_buffer.insert_text.connect (this.text_inserted);
    this.text_buffer.delete_range.connect (this.range_deleted);
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

  public static Document from_file (string path) throws GLib.Error {
    return new Document (path);
  }

  public static Document empty () throws GLib.Error {
    return new Document (null);
  }
}
