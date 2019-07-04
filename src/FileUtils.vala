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
}