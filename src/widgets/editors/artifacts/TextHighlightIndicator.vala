namespace Manuscript.Widgets {
    public class TextHighlightIndicator : Gtk.Button {
        private Gdk.Cursor hover_cursor;
        construct {
            hover_cursor = new Gdk.Cursor.from_name (Gdk.Display.get_default (), "pointer");
            var icon = new Gtk.Image ();
            icon.gicon = new ThemedIcon ("format-text-highlight");
            icon.pixel_size = 24;
            child = icon;

            var style_context = get_style_context ();
            style_context.add_class (Gtk.STYLE_CLASS_FLAT);
            style_context.add_class ("text-highlight-indicator");

            show_all ();
        }

        public void resize (int size) {
            ((Gtk.Image) get_child ()).pixel_size = size;
        }
    }
}
