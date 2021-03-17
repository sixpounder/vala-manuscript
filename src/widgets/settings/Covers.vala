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

 namespace Manuscript.Widgets.Settings {
    public class CoversSettingsView : Gtk.Grid {
        public weak Manuscript.Window parent_window { get; construct; }
        public weak Services.DocumentManager document_manager { get; private set; }
        public Gtk.Switch inline_cover_images_switch { get; private set; }

        public CoversSettingsView (Manuscript.Window parent_window) {
            Object (
                parent_window: parent_window,
                expand: true,
                halign: Gtk.Align.CENTER,
                valign: Gtk.Align.START,
                column_spacing: 10,
                row_spacing: 10
            );
        }

        construct {
            document_manager = parent_window.document_manager;

            inline_cover_images_switch = new Gtk.Switch ();
            inline_cover_images_switch.halign = Gtk.Align.END;

            var inline_cover_images_label = new Gtk.Label (_("Inline cover images"));
            inline_cover_images_label.halign = Gtk.Align.START;

            var inline_cover_images_hint = new Gtk.Label (
                _("<small>Store cover images inline into the manuscript (increases file size).\n<b>Existing covers are not affected by the change of this setting</b></small>") // vala-lint=line-length
            );
            inline_cover_images_hint.use_markup = true;
            inline_cover_images_hint.halign = Gtk.Align.START;

            attach_next_to (inline_cover_images_label, null, Gtk.PositionType.LEFT, 1);
            attach_next_to (inline_cover_images_switch, inline_cover_images_label, Gtk.PositionType.RIGHT, 1);
            attach_next_to (inline_cover_images_hint, inline_cover_images_label, Gtk.PositionType.BOTTOM, 2);

            connect_events ();
            show_all ();
        }

        protected void connect_events () {
            inline_cover_images_switch.state_set.connect (on_switch_change);
            document_manager.document.settings.notify["inline_cover_images"].connect (update_ui);
        }

        ~ CoversSettingsView () {
            inline_cover_images_switch.state_set.disconnect (on_switch_change);
            document_manager.document.settings.notify["inline_cover_images"].disconnect (update_ui);
        }

        private bool on_switch_change (bool state) {
            update_settings ();
            return false;
        }

        protected void update_ui () {
            inline_cover_images_switch.active = document_manager.document.settings.inline_cover_images;
        }

        protected void update_settings () {
            document_manager.document.settings.inline_cover_images = inline_cover_images_switch.active;
        }
    }
}
