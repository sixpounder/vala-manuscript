namespace Manuscript {
    public class DocumentTagTable : Gtk.TextTagTable {

        public Gtk.TextTag light_dimmed;
        public Gtk.TextTag light_focused;
        public Gtk.TextTag dark_dimmed;
        public Gtk.TextTag dark_focused;

        construct {
            light_dimmed = new Gtk.TextTag ("light-dimmed");
            light_dimmed.foreground = "#ccc";

            light_focused = new Gtk.TextTag ("light-focused");
            light_focused.foreground = "#333";

            dark_dimmed = new Gtk.TextTag ("dark-dimmed");
            dark_dimmed.foreground = "#666666";

            dark_focused = new Gtk.TextTag ("dark-focused");
            dark_focused.foreground = "#fafafa";

            add (light_dimmed);
            add (light_focused);
            add (dark_dimmed);
            add (dark_focused);
        }

        public Gtk.TextTag[] for_theme (string? theme) {
            switch (theme) {
                case "light":
                default:
                    return { light_dimmed, light_focused };
                case "dark":
                    return { dark_dimmed, dark_focused };
            }
        }
    }
}
