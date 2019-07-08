public enum ChangeType {
  INSERTION,
  DELETION
}

public class DocumentChange : Object {
  public ChangeType change_type { get; set; }
  public Gtk.TextIter start { get; internal set; }
  public Gtk.TextIter end { get; internal set; }
  public string text;
  public uint text_length;

  protected DocumentChange (ChangeType change_type) {
    Object(
      change_type: change_type
    );
  }

  public static DocumentChange insertion (Gtk.TextIter start, string text, uint text_length) {
    DocumentChange dc = new DocumentChange(ChangeType.INSERTION);
    dc.start = start;
    dc.text = text;
    dc.text_length = text_length;
    return dc;
  }

  public static DocumentChange deletion (Gtk.TextIter start, Gtk.TextIter end) {
    DocumentChange dc = new DocumentChange(ChangeType.DELETION);
    dc.end = end;
    return dc;
  }
}
