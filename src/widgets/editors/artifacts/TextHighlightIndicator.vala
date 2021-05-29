namespace Manuscript.Widgets {
    public class TextHighlightIndicator : Gtk.Image {
        construct {
            gicon = new ThemedIcon ("format-text-highlight");
            pixel_size = 24;
        }

        public void resize (int size) {
            pixel_size = size;
        }
    }
}
