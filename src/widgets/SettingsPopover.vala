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
        public Gtk.Application application { get; construct; }
        public Gtk.Switch focus_mode_switch { get; private set; }
        public Gtk.Switch autosave_switch { get; private set; }
        public Gtk.Switch use_document_font_switch { get; private set; }
        public Services.AppSettings settings { get; private set; }
        public Gtk.Button zoom_default_button { get; private set; }

        public SettingsPopover (Gtk.Application application) {
            Object (
                modal: true,
                application: application
            );
        }

        construct {
            modal = true;
            set_size_request (-1, -1);

            settings = Services.AppSettings.get_default ();

            layout = new Gtk.Grid ();
            layout.get_style_context ().add_class ("px-2");
            layout.column_spacing = 6;
            layout.row_spacing = 10;
            layout.margin_bottom = 6;
            layout.margin_top = 12;
            layout.orientation = Gtk.Orientation.VERTICAL;
            layout.column_homogeneous = true;

            var zoom_out_button = new Gtk.Button.from_icon_name ("zoom-out-symbolic", Gtk.IconSize.MENU);
            zoom_out_button.action_name =
                Services.ActionManager.ACTION_PREFIX + Services.ActionManager.ACTION_ZOOM_OUT_FONT;
            zoom_out_button.tooltip_markup = Granite.markup_accel_tooltip (
                application.get_accels_for_action (zoom_out_button.action_name),
                _("Zoom out")
            );

            zoom_default_button = new Gtk.Button.with_label (font_scale_to_zoom (settings.text_scale_factor));
            zoom_default_button.action_name =
                Services.ActionManager.ACTION_PREFIX + Services.ActionManager.ACTION_ZOOM_DEFAULT_FONT;
            zoom_default_button.tooltip_markup = Granite.markup_accel_tooltip (
                application.get_accels_for_action (zoom_default_button.action_name),
                _("Default zoom level")
            );

            var zoom_in_button = new Gtk.Button.from_icon_name ("zoom-in-symbolic", Gtk.IconSize.MENU);
            zoom_in_button.action_name =
                Services.ActionManager.ACTION_PREFIX + Services.ActionManager.ACTION_ZOOM_IN_FONT;
            zoom_in_button.tooltip_markup = Granite.markup_accel_tooltip (
                application.get_accels_for_action (zoom_in_button.action_name),
                _("Zoom in")
            );

            var font_size_grid = new Gtk.Grid ();
            font_size_grid.column_homogeneous = true;
            font_size_grid.hexpand = true;
            font_size_grid.margin_start = font_size_grid.margin_end = 0;
            font_size_grid.margin_bottom = 6;
            font_size_grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);

            font_size_grid.add (zoom_out_button);
            font_size_grid.add (zoom_default_button);
            font_size_grid.add (zoom_in_button);

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

            Gtk.Label use_document_font_label = new Gtk.Label (_("Use document font"));
            use_document_font_label.halign = Gtk.Align.START;
            use_document_font_switch = new Gtk.Switch ();
            use_document_font_switch.expand = false;
            use_document_font_switch.halign = Gtk.Align.END;
            use_document_font_switch.active = settings.use_document_font;
            use_document_font_switch.tooltip_markup = _("When toggled on, text editors will try to use the font specified in current document typographic settings"); // vala-lint=line-length
            use_document_font_switch.state_set.connect (() => {
                update_settings ();
                return false;
            });

            Gtk.Label focus_mode_label = new Gtk.Label (_("Focus mode"));
            focus_mode_label.halign = Gtk.Align.START;
            focus_mode_switch = new Gtk.Switch ();
            focus_mode_switch.expand = false;
            focus_mode_switch.halign = Gtk.Align.END;
            focus_mode_switch.active = settings.focus_mode;
            focus_mode_switch.tooltip_markup = _("Reduces interface noise so you can focus on writing"); // vala-lint=line-length
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
            autosave_switch.tooltip_markup = _("Automatically save the document when edits are made"); // vala-lint=line-length
            autosave_switch.state_set.connect (() => {
                update_settings ();
                return false;
            });

            var sep = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

            layout.attach_next_to (font_size_grid, null, Gtk.PositionType.LEFT, 2);
            layout.attach_next_to (color_button_white, font_size_grid, Gtk.PositionType.BOTTOM, 1);
            layout.attach_next_to (color_button_dark, color_button_white, Gtk.PositionType.RIGHT, 1);
            layout.attach_next_to (sep, color_button_white, Gtk.PositionType.BOTTOM, 2);
            layout.attach_next_to (focus_mode_label, sep, Gtk.PositionType.BOTTOM);
            layout.attach_next_to (focus_mode_switch, focus_mode_label, Gtk.PositionType.RIGHT);
            layout.attach_next_to (use_document_font_label, focus_mode_label, Gtk.PositionType.BOTTOM);
            layout.attach_next_to (use_document_font_switch, use_document_font_label, Gtk.PositionType.RIGHT);
            layout.attach_next_to (autosave_label, use_document_font_label, Gtk.PositionType.BOTTOM);
            layout.attach_next_to (autosave_switch, autosave_label, Gtk.PositionType.RIGHT);
            layout.show_all ();

            add (layout);

            settings.change.connect (update_ui);
        }

        ~SettingsPopover () {
            settings.change.disconnect (update_ui);
        }

        protected void update_ui (string? for_key = null) {
            focus_mode_switch.active = settings.focus_mode;
            autosave_switch.active = settings.autosave;
            use_document_font_switch.active = settings.use_document_font;
            zoom_default_button.label = font_scale_to_zoom (settings.text_scale_factor);
        }

        protected void update_settings () {
            settings.focus_mode = focus_mode_switch.active;
            settings.autosave = autosave_switch.active;
            settings.use_document_font = use_document_font_switch.active;
        }

        private string font_scale_to_zoom (double font_scale) {
            return ("%.0f%%").printf (font_scale * 100);
        }
    }
}
