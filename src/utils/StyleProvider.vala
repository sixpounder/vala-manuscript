public Gtk.CssProvider get_editor_style () {
    Gtk.CssProvider provider = new Gtk.CssProvider ();

    try {
        provider.load_from_data (
            """textview {
                font: 18px iA Writer Duospace;
            }"""
        );
    } catch {
        // skip
    }

    return provider;
}
