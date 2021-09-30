namespace Manuscript.Widgets {
    public class TextHighlightIndicator : Gtk.Button {
        construct {
            var icon = new Gtk.Image ();
            icon.gicon = new ThemedIcon ("format-text-highlight");
            icon.pixel_size = 24;
            child = icon;

            var style_context = get_style_context ();
            style_context.add_class (Gtk.STYLE_CLASS_FLAT);

            show_all ();
        }

        public void resize (int size) {
            ((Gtk.Image) get_child ()).pixel_size = size;
        }
    }
}
