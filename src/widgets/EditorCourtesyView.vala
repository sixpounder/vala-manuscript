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
    public class EditorCourtesyView : Gtk.Box {
        public weak Manuscript.Services.DocumentManager document_manager { get; construct; }
        protected Gtk.Button action_button { get; set; }

        public EditorCourtesyView (Manuscript.Services.DocumentManager document_manager ) {
            Object (
                orientation: Gtk.Orientation.VERTICAL,
                document_manager: document_manager
            );
        }

        construct {
            spacing = 10;
            valign = Gtk.Align.CENTER;
            halign = Gtk.Align.CENTER;

            var header_label = new Gtk.Label (_("Select something to edit"));
            header_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

            var or_label = new Gtk.Label (_("or"));

            action_button = new Gtk.Button.with_label (_("Add a new chapter"));
            action_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            action_button.clicked.connect (on_suggested_action);

            pack_start (header_label);
            pack_start (or_label);
            pack_start (action_button);
        }

        ~ EditorCourtesyView () {
            action_button.activate.disconnect (on_suggested_action);
        }

        private void on_suggested_action () {
            document_manager.add_chunk (new Models.DocumentChunk.empty (Models.ChunkType.CHAPTER));
        }
    }
}
