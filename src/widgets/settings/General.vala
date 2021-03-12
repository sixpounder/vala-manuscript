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
    public class DocumentGeneralSettingsView : Gtk.Grid {
        public weak Manuscript.Window parent_window { get; construct; }
        public weak Services.DocumentManager document_manager { get; private set; }
        public Gtk.Entry title_input { get; private set; }

        public DocumentGeneralSettingsView (Manuscript.Window parent_window) {
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

            Gtk.Label title_label = new Gtk.Label (_("Manuscript title"));
            title_label.halign = Gtk.Align.END;

            title_input = new Gtk.Entry ();
            title_input.expand = true;
            title_input.halign = Gtk.Align.FILL;
            title_input.placeholder_text = _("Type a title for your manuscript");
            title_input.text = document_manager.document.title;
            title_input.changed.connect (() => {
                document_manager.document.title = title_input.text;
            });

            attach (title_label, 0, 0, 1, 1);
            attach (title_input, 1, 0, 1, 1);
        }
    }
}
