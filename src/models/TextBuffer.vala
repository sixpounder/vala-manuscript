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
        public TextBuffer () {
            Object (
                tag_table: new XManuscriptTagTable ()
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

        public uint8[] serialize_manuscript () {
            var atom = get_manuscript_serialize_format ();
            Gtk.TextIter start, end, cursor;
            get_start_iter (out start);
            get_end_iter (out end);
            cursor = start;

            while (!cursor.is_end ()) {
                var possible_anchor = cursor.get_child_anchor ();
                if (possible_anchor != null) {
                    this.delete (ref cursor, ref cursor);
                }
                cursor.forward_char ();
            }

            /**
             *   ___         ___  
             *  (o o)       (o o) 
             * (  V  ) WTF (  V  )
             * --m-m---------m-m--
             *
             * - serialize method goes full recursion if there are child anchors in the buffer
             * - if the user has searched anything, an anonymous Gtk.TextTag is applied to search results,
             *   it gets serialized and fucks shit up when the buffer is loaded again
             */
            return serialize (this, atom, start, end);
        }

        public bool deserialize_manuscript (uint8[] raw_content, Gtk.TextIter at_iter) throws Error {
            return deserialize (this, this.get_manuscript_deserialize_format (), at_iter, raw_content);
        }
    }
}
