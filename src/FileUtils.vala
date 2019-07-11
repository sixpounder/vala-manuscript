public class FileUtils : Object {
  public FileUtils () {

  }

  public static string read (string path) throws Error {
    File file = File.new_for_path(path);
    try {
		  uint8[] contents;
		  string etag_out;

		  file.load_contents (null, out contents, out etag_out);

		  return (string) contents;
	  } catch (Error e) {
		  throw e;
	  }
  }

  public static void save_buffer (Gtk.TextBuffer buffer, string path) throws Error {
    FileUtils.save(buffer.text, path);
  }

  public static void save (string text, string path) throws Error {
    try {
      File file = File.new_for_path(path);

      // delete if file already exists
      if (file.query_exists ()) {
          file.delete ();
      }

      var dos = new DataOutputStream (new BufferedOutputStream.sized (file.create (FileCreateFlags.REPLACE_DESTINATION), 65536));

      uint8[] data = text.data;
      long written = 0;
      while (written < data.length) {
        // sum of the bytes of 'text' that already have been written to the stream
        written += dos.write (data[written:data.length]);
      }
    } catch (Error e) {
      stderr.printf ("%s\n", e.message);
      throw e;
    }

  }
}
