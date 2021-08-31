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
    public class CharacterSheetEditor : Gtk.ScrolledWindow, Protocols.ChunkEditor {
        public weak Models.CharacterSheetChunk chunk { get; construct; }
        public weak Manuscript.Window parent_window { get; construct; }

        protected Gtk.Entry name_entry { get; set; }
        protected Gtk.Entry traits_entry { get; set; }
        protected Gtk.TextView background_entry { get; set; }
        protected Gtk.TextView notes_entry { get; set; }

        public CharacterSheetEditor (Manuscript.Window parent_window, Models.CharacterSheetChunk chunk) {
            Object (
                parent_window: parent_window,
                chunk: chunk
            );
        }

        construct {
            assert (chunk != null);
            assert (chunk.kind == Manuscript.Models.ChunkType.CHARACTER_SHEET);

            kinetic_scrolling = true;
            overlay_scrolling = true;
            hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
            vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;

            get_style_context ().add_class ("character-sheet-editor");

            Gtk.Grid layout = new Gtk.Grid ();
            layout.get_style_context ().add_class ("p-4");
            layout.expand = true;
            layout.orientation = Gtk.Orientation.VERTICAL;
            layout.valign = Gtk.Align.START;
            layout.halign = Gtk.Align.FILL;
            layout.column_spacing = 40;
            layout.row_spacing = 20;
            layout.column_homogeneous = false;
            layout.row_homogeneous = false;

            Gtk.Label name_label = make_entry_label (_("Character name"));
            name_entry = make_entry (_("Type the name of the character you are describing"));
            name_entry.text = chunk.name;

            Gtk.Label background_label = make_entry_label (_("Background"));
            background_entry = make_textbox ();
            background_entry.buffer.text = chunk.background;
            background_entry.height_request = 300;

            Gtk.Label traits_label = make_entry_label (_("Traits"));
            traits_entry = make_entry (_("Type the main physical and/or behavioural traits defining the character"));
            traits_entry.text = chunk.traits;

            Gtk.Label notes_label = make_entry_label (_("Notes"));
            notes_entry = make_textbox ();
            notes_entry.buffer.text = chunk.notes;
            notes_entry.height_request = 300;

            layout.attach_next_to (name_label, null, Gtk.PositionType.LEFT, 1);
            layout.attach_next_to (name_entry, name_label, Gtk.PositionType.RIGHT, 2);

            layout.attach_next_to (traits_label, name_label, Gtk.PositionType.BOTTOM, 1);
            layout.attach_next_to (traits_entry, traits_label, Gtk.PositionType.RIGHT, 2);

            layout.attach_next_to (background_label, traits_label, Gtk.PositionType.BOTTOM, 1);
            layout.attach_next_to (background_entry, background_label, Gtk.PositionType.RIGHT, 2);

            layout.attach_next_to (notes_label, background_label, Gtk.PositionType.BOTTOM, 1);
            layout.attach_next_to (notes_entry, notes_label, Gtk.PositionType.RIGHT, 2);

            add (layout);

            connect_events ();

            reflect_lock_status ();

            show_all ();
        }

        ~ CharacterSheetEditor () {
            chunk.parent_document.saved.disconnect (on_document_saved);
            name_entry.changed.disconnect (update_model);
            background_entry.buffer.changed.disconnect (update_model);
            traits_entry.changed.disconnect (update_model);
            notes_entry.buffer.changed.disconnect (update_model);
        }

        private void connect_events () {
            chunk.parent_document.saved.connect (on_document_saved);
            name_entry.changed.connect (update_model);
            background_entry.buffer.changed.connect (update_model);
            traits_entry.changed.connect (update_model);
            notes_entry.buffer.changed.connect (update_model);
            chunk.notify["locked"].connect (reflect_lock_status);
        }

        private Gtk.Label make_entry_label (string text) {
            Gtk.Label label = new Gtk.Label (text);
            label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            label.xalign = 1;

            return label;
        }

        private Gtk.Entry make_entry (string? placeholder = null) {
            Gtk.Entry entry = new Gtk.Entry ();
            entry.expand = true;
            //  entry.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            if (placeholder != null) {
                entry.placeholder_text = placeholder;
            }

            return entry;
        }

        private Gtk.TextView make_textbox (string? placeholder = null) {
            Gtk.TextView entry = new Gtk.TextView.with_buffer (new Gtk.TextBuffer (null));
            entry.expand = true;
            entry.wrap_mode = Gtk.WrapMode.WORD;
            return entry;
        }

        private void reflect_lock_status () {
            if (chunk.locked) {
                lock_editor ();
            } else {
                unlock_editor ();
            }
        }

        private void on_document_saved () {
            chunk.has_changes = false;
        }

        public void focus_editor () {
            name_entry.grab_focus_without_selecting ();
        }

        public void lock_editor () {
            sensitive = false;
        }

        public void unlock_editor () {
            sensitive = true;
        }

        public void update_model () {
            chunk.name = name_entry.text;
            chunk.background = background_entry.buffer.text;
            chunk.traits = traits_entry.text;
            chunk.notes = notes_entry.buffer.text;
            chunk.has_changes = true;
        }
    }
}
