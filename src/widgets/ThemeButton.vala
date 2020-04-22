namespace Manuscript {
    public class ThemeButton : Gtk.Button {
        public string theme_name { get; set; }

        public signal void selected (string name);

        public ThemeButton (string theme, int size = 32) {
            Object (
                theme_name: theme,
                height_request: size,
                width_request: size,
                tooltip_text: Utils.Strings.ucfirst (theme)
            );

            var color_context = get_style_context ();
            color_context.add_class ("theme-button");
            color_context.add_class ("circular");
            color_context.add_class (@"theme-button-$theme_name");
            clicked.connect (on_click);
        }

        ~ ThemeButton () {
            clicked.disconnect (on_click);
        }

        protected void on_click () {
            selected (theme_name);
        }
    }
}
