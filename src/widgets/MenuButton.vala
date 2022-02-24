/*
 * Copyright 2022 Andrea Coronese <sixpounder@protonmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Manuscript.Widgets {

    public enum MenuButtonHint {
        DROPDOWN_MENU,
        MODAL,
        NONE
    }
    public class MenuButton : Gtk.Grid {
        public signal void activated ();

        public MenuButtonHint hint { get; set; }

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

        public MenuButton.with_properties (string icon_name, string title, string? accels = null) {
            button = new Gtk.MenuButton ();
            button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            button.can_focus = false;
            var icon = new Gtk.Image ();
            icon.gicon = new ThemedIcon (icon_name);
            icon.pixel_size = 24;
            button.image = icon;

            if (accels != null) {
                button.action_name = accels;
                button.clicked.connect (() => {
                    if (hint == MenuButtonHint.MODAL) {
                        button.set_state_flags (Gtk.StateFlags.NORMAL, true);
                    }
                });
            } else {
                button.clicked.connect (() => {
                    on_activate (button);
                });
            }

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
            hint = MenuButtonHint.NONE;
        }

        protected void on_activate (Gtk.Widget ? widget = null, Gdk.Event ? event = null) {
            activated ();
        }
    }
}
