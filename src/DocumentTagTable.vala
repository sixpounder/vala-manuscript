public class DocumentTagTable : Gtk.TextTagTable {

  public Gtk.TextTag lightDimmed;
  public Gtk.TextTag lightFocused;
  public Gtk.TextTag darkDimmed;
  public Gtk.TextTag darkFocused;

  construct {
    lightDimmed = new Gtk.TextTag ("light-dimmed");
    lightDimmed.foreground = "#ccc";

    lightFocused = new Gtk.TextTag ("light-focused");
    lightFocused.foreground = "#333";

    darkDimmed = new Gtk.TextTag ("dark-dimmed");
    darkFocused = new Gtk.TextTag ("dark-focused");

    add (lightDimmed);
    add (lightFocused);
    add (darkDimmed);
    add (darkFocused);
  }
}

