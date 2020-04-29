namespace Manuscript.Widgets {
    public class MenuButton : Gtk.Grid {
        public signal void activated ();

        public Gtk.MenuButton button { get; protected set; }
        public Gtk.Label label { get; protected set; }

        public GLib.MenuModel menu_model {
            get {
                return button != null ? button.menu_model : null;
            }
            set {
                if (button != null) {
                    button.menu_model = value;
                }
            }
        }

        public Gtk.Popover popover {
            get {
                return button.popover;
            }
            set {
                button.popover = value;
            }
        }

        public MenuButton.with_icon_name (string icon_name) {
            this.with_properties (icon_name, "");
        }

        public MenuButton.with_properties (string icon_name, string title, string[]? accels = null) {
            button = new Gtk.MenuButton ();
            button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            button.can_focus = false;
            var icon = new Gtk.Image ();
            icon.gicon = new ThemedIcon (icon_name);
            icon.pixel_size = 24;
            button.image = icon;
            button.clicked.connect (() => {
                on_activate (button);
            });

            button.touch_event.connect (() => {
                on_activate ();
                return true;
            });

            label = new Gtk.Label (null);
            label.set_markup (@"<small>$title</small>");
            label.button_release_event.connect (() => {
                on_activate ();
                return true;
            });
            label.touch_event.connect (() => {
                on_activate ();
                return true;
            });

            attach (button, 0, 0, 1, 1);
            attach (label, 0, 1, 1, 1);
        }

        construct {
            orientation = Gtk.Orientation.HORIZONTAL;
            valign = Gtk.Align.CENTER;
            halign = Gtk.Align.FILL;
            expand = false;
        }

        protected void on_activate (Gtk.Widget ? widget = null, Gdk.Event ? event = null) {
            activated ();
        }
    }
}
