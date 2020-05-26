namespace Manuscript.Widgets {
    public class SettingsPopover : Gtk.Popover {
        protected Gtk.Grid layout;
        protected Gtk.Box theme_layout;
        protected ThemeButton light_theme_button;
        protected ThemeButton dark_theme_button;
        protected ThemeButton sepia_theme_button;
        public Gtk.Switch zen_switch { get; private set; }
        public Services.AppSettings settings { get; private set; }

        public SettingsPopover (Gtk.Widget relative_to) {
            Object (
                relative_to: relative_to
            );
        }

        construct {
            set_size_request (300, -1);

            settings = Services.AppSettings.get_default ();

            layout = new Gtk.Grid ();
            layout.halign = Gtk.Align.CENTER;
            layout.margin_top = 10;
            layout.margin_bottom = 10;
            layout.row_spacing = 15;
            layout.column_spacing = 15;
            layout.column_homogeneous = true;

            theme_layout = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);

            light_theme_button = new ThemeButton ("Light");
            sepia_theme_button = new ThemeButton ("Sepia");
            dark_theme_button = new ThemeButton ("Dark");

            light_theme_button.selected.connect (on_theme_set);
            sepia_theme_button.selected.connect (on_theme_set);
            dark_theme_button.selected.connect (on_theme_set);

            theme_layout.pack_start (light_theme_button, false, true, 15);
            theme_layout.pack_start (sepia_theme_button, false, true, 15);
            theme_layout.pack_start (dark_theme_button, false, true, 15);

            layout.attach (theme_layout, 0, 0, 2, 1);

            layout.attach (new Gtk.Separator (Gtk.Align.HORIZONTAL), 0, 1, 2, 1);

            Gtk.Label autosave_label = new Gtk.Label (_("Focus mode"));
            autosave_label.halign = Gtk.Align.START;

            zen_switch = new Gtk.Switch ();
            zen_switch.expand = false;
            zen_switch.halign = Gtk.Align.END;
            zen_switch.active = settings.zen;
            zen_switch.state_set.connect (() => {
                update_settings ();
                return false;
            });

            layout.attach (autosave_label, 0, 2, 1, 1);
            layout.attach (zen_switch, 1, 2, 1, 1);

            add (layout);
        }

        ~SettingsPopover () {
            light_theme_button.selected.disconnect (on_theme_set);
            dark_theme_button.selected.disconnect (on_theme_set);
        }

        protected void on_theme_set (string theme) {
            var settings = Services.AppSettings.get_default ();
            settings.theme = theme;
        }

        protected void update_settings () {
            settings.zen = zen_switch.active;
        }
    }
}
