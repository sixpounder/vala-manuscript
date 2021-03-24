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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Manuscript.Models {
    public class TextBuffer : Gtk.SourceBuffer {
        private Gdk.Atom serialize_atom;
        private Gdk.Atom deserialize_atom;
        public TextBuffer (Models.DocumentTagTable? tag_table) {
            Object (
                tag_table: tag_table
            );
        }

        construct {
            serialize_atom = register_serialize_tagset ("x-manuscript");
            deserialize_atom = register_deserialize_tagset ("x-manuscript");
        }

        public Gdk.Atom get_manuscript_serialize_format () {
            return serialize_atom;
        }

        public Gdk.Atom get_manuscript_deserialize_format () {
            return deserialize_atom;
        }
    }
}
