public class Document : Object {

  public signal void saved (string target_path);
  public signal void load ();

  protected Gtk.TextBuffer _buffer;
  protected string _raw_content;

  public string file_path { get; construct; }
  public string raw_content {
    get {
      return this._raw_content;
    }
    set {
      this._raw_content = value;
      this._buffer = new Gtk.TextBuffer(null);
      this._buffer.set_text(this._raw_content, this._raw_content.length);
    }
  }

  public Gtk.TextBuffer text_buffer {
    get {
      return this._buffer;
    }

    set {}
  }

  protected Document (string? file_path) throws GLib.Error {
    Object(
      file_path: file_path
    );

    if (this.file_path == null) {
      // Create transient document
    } else {
      // Open from file_path
      debug("Loading " + this.file_path);
      this.raw_content = FileUtils.read(this.file_path);
      this.load();
    }
  }

  public void save () {
    this.saved(this.file_path);
  }

  public void unload () {
    this.text_buffer.dispose();
  }

  public static Document from_file (string path) throws GLib.Error {
    return new Document(path);
  }

  public static Document empty () throws GLib.Error {
    return new Document(null);
  }
}