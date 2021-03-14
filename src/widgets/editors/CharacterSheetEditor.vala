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
    public class CharacterSheetEditor : Gtk.Grid, Protocols.ChunkEditor {
        public weak Models.CharacterSheetChunk chunk { get; construct; }
        public weak Manuscript.Window parent_window { get; construct; }

        protected Gtk.Entry name_entry { get; set; }
        protected Gtk.Entry synopsis_entry { get; set; }
        protected Gtk.Entry traits_entry { get; set; }
        protected Gtk.TextView notes_entry { get; set; }

        public CharacterSheetEditor (Manuscript.Window parent_window, Models.CharacterSheetChunk chunk) {
            Object (
                parent_window: parent_window,
                chunk: chunk,
                expand: true,
                orientation: Gtk.Orientation.VERTICAL,
                valign: Gtk.Align.START,
                halign: Gtk.Align.FILL,
                column_spacing: 40,
                row_spacing: 20,
                column_homogeneous: false,
                row_homogeneous: false
            );
        }

        construct {
            assert (chunk.kind == Manuscript.Models.ChunkType.CHARACTER_SHEET);

            get_style_context ().add_class ("p-4");
            get_style_context ().add_class ("character-sheet-editor");

            Gtk.Label name_label = make_entry_label (_("Character name"));
            name_entry = make_entry ();

            Gtk.Label synopsis_label = make_entry_label (_("Synopsis"));
            synopsis_entry = make_entry ();

            Gtk.Label traits_label = make_entry_label (_("Traits"));
            traits_entry = make_entry ();

            Gtk.Label notes_label = make_entry_label (_("Notes"));
            notes_entry = make_textbox ();
            notes_entry.height_request = 300;

            attach_next_to (name_label, null, Gtk.PositionType.LEFT, 1);
            attach_next_to (name_entry, name_label, Gtk.PositionType.RIGHT, 2);
            
            attach_next_to (synopsis_label, name_label, Gtk.PositionType.BOTTOM, 1);
            attach_next_to (synopsis_entry, synopsis_label, Gtk.PositionType.RIGHT, 2);

            attach_next_to (traits_label, synopsis_label, Gtk.PositionType.BOTTOM, 1);
            attach_next_to (traits_entry, traits_label, Gtk.PositionType.RIGHT, 2);

            attach_next_to (notes_label, traits_label, Gtk.PositionType.BOTTOM, 1);
            attach_next_to (notes_entry, notes_label, Gtk.PositionType.RIGHT, 2);

            show_all ();
        }

        private Gtk.Label make_entry_label (string text) {
            Gtk.Label label = new Gtk.Label (text);
            label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            label.xalign = 1;

            return label;
        }

        private Gtk.Entry make_entry (string placeholder = "") {
            Gtk.Entry entry = new Gtk.Entry ();
            entry.expand = true;
            entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            if (placeholder != "") {
                entry.placeholder_text = placeholder;
            }

            return entry;
        }

        private Gtk.TextView make_textbox () {
            Gtk.TextView entry = new Gtk.TextView ();
            entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

            return entry;
        }

        public void focus_editor () {
            name_entry.grab_focus_without_selecting ();
        }
    }
}
