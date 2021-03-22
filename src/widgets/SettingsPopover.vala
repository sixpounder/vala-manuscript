/*
 * Copyright 2021 Andrea Coronese <sixpounder@protonmail.com>
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
    public class SettingsPopover : Gtk.Popover {
        protected Gtk.Grid layout;
        protected Gtk.Box theme_layout;
        public Gtk.Switch focus_mode_switch { get; private set; }
        public Gtk.Switch autosave_switch { get; private set; }
        public Services.AppSettings settings { get; private set; }

        public SettingsPopover () {
            Object (
                modal: true
            );
        }

        construct {
            modal = true;
            set_size_request (-1, -1);
            get_style_context ().add_class ("p-2");

            settings = Services.AppSettings.get_default ();

            layout = new Gtk.Grid ();
            layout.column_spacing = 6;
            layout.margin_bottom = 6;
            layout.margin_top = 12;
            layout.orientation = Gtk.Orientation.VERTICAL;
            layout.row_spacing = 6;
            layout.column_homogeneous = true;

            var color_button_white = new Gtk.RadioButton (null);
            color_button_white.active = settings.theme == "Light";
            color_button_white.halign = Gtk.Align.CENTER;
            color_button_white.tooltip_text = _("Light");
            color_button_white.toggled.connect (() => {
                if (color_button_white.active) {
                    settings.theme = "Light";
                    settings.prefer_dark_style = false;
                }
            });

            var color_button_white_context = color_button_white.get_style_context ();
            color_button_white_context.add_class (Granite.STYLE_CLASS_COLOR_BUTTON);
            color_button_white_context.add_class ("color-white");

            var color_button_dark = new Gtk.RadioButton (null);
            color_button_dark.set_group (color_button_white.get_group ());
            color_button_dark.active = settings.theme == "Dark" || settings.prefer_dark_style;
            color_button_dark.halign = Gtk.Align.CENTER;
            color_button_dark.tooltip_text = _("Dark");
            color_button_dark.toggled.connect (() => {
                if (color_button_dark.active) {
                    settings.theme = "Dark";
                    settings.prefer_dark_style = true;
                }
            });

            var color_button_dark_context = color_button_dark.get_style_context ();
            color_button_dark_context.add_class (Granite.STYLE_CLASS_COLOR_BUTTON);
            color_button_dark_context.add_class ("color-dark");

            Gtk.Label zen_label = new Gtk.Label (_("Focus mode"));
            zen_label.halign = Gtk.Align.START;

            focus_mode_switch = new Gtk.Switch ();
            focus_mode_switch.expand = false;
            focus_mode_switch.halign = Gtk.Align.END;
            focus_mode_switch.active = settings.focus_mode;
            focus_mode_switch.state_set.connect (() => {
                update_settings ();
                return false;
            });

            Gtk.Label autosave_label = new Gtk.Label (_("Autosave"));
            autosave_label.halign = Gtk.Align.START;
            autosave_switch = new Gtk.Switch ();
            autosave_switch.expand = false;
            autosave_switch.halign = Gtk.Align.END;
            autosave_switch.active = settings.autosave;
            autosave_switch.state_set.connect (() => {
                update_settings ();
                return false;
            });

            var sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

            layout.attach_next_to (color_button_white, null, Gtk.PositionType.LEFT, 1);
            layout.attach_next_to (color_button_dark, color_button_white, Gtk.PositionType.RIGHT, 1);
            layout.attach_next_to (sep, color_button_white, Gtk.PositionType.BOTTOM, 2);
            layout.attach_next_to (zen_label, sep, Gtk.PositionType.BOTTOM);
            layout.attach_next_to (focus_mode_switch, zen_label, Gtk.PositionType.RIGHT);
            layout.attach_next_to (autosave_label, zen_label, Gtk.PositionType.BOTTOM);
            layout.attach_next_to (autosave_switch, autosave_label, Gtk.PositionType.RIGHT);

            layout.show_all ();

            add (layout);

            settings.change.connect (update_ui);
        }

        ~SettingsPopover () {
            settings.change.disconnect (update_ui);
        }

        protected void on_theme_set (string theme) {
            var settings = Services.AppSettings.get_default ();
            settings.theme = theme;
        }

        protected void update_ui (string? for_key = null) {
            focus_mode_switch.active = settings.focus_mode;
            autosave_switch.active = settings.autosave;
        }

        protected void update_settings () {
            settings.focus_mode = focus_mode_switch.active;
            settings.autosave = autosave_switch.active;
        }
    }
}
