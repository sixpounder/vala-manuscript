namespace Manuscript {
  public class SidebarRow: Gtk.ListBoxRow {
    public string label { get; set; }
    public Gee.List<Gtk.ListBoxRow> children { get; set; }

    public SidebarRow (string label, Gee.List<Gtk.ListBoxRow>? children) {
      Object (
        label: label,
        children: children,
        selectable: true,
        activatable: true
      );
    }

    construct {
      var label = new Gtk.Label (label);
      add (label);
    }
  }
}

