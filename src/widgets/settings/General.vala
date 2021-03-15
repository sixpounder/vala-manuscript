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
        public Gtk.Entry title_input { get; construct; }
        public Gtk.Entry author_input { get; construct; }

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
            title_label.xalign = 1;
            title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

            title_input = new Gtk.Entry ();
            title_input.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            title_input.expand = true;
            title_input.halign = Gtk.Align.FILL;
            title_input.placeholder_text = _("Type a title for your manuscript");

            if (document_manager.document.title != null) {
                title_input.text = document_manager.document.title;
            }

            title_input.changed.connect (() => {
                document_manager.document.title = title_input.text;
            });

            Gtk.Label author_label = new Gtk.Label (_("Author"));
            author_label.xalign = 1;
            author_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

            author_input = new Gtk.Entry ();
            author_input.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            author_input.text = document_manager.document.settings.author_name;
            author_input.changed.connect (() => {
                document_manager.document.settings.author_name = author_input.text;
            });

            attach_next_to (title_label, null, Gtk.PositionType.LEFT);
            attach_next_to (title_input, title_label, Gtk.PositionType.RIGHT);

            attach_next_to (author_label, title_label, Gtk.PositionType.BOTTOM);
            attach_next_to (author_input, author_label, Gtk.PositionType.RIGHT);

            show_all ();
        }
    }
}
