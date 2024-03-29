/*
 * Copyright 2022 Andrea Coronese <sixpounder@protonmail.com>
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

namespace Manuscript.Models.Lib {

    public class TextBufferSerializer : Object {
        public uint8[] serialize (Models.TextBuffer buffer) throws IOError {
            StringBuilder serialized_buffer = new StringBuilder ();
            Gee.ArrayList<Gee.ArrayList<uint8>> serialized_artifacts = new Gee.ArrayList<Gee.ArrayList<uint8>> ();
            int artifacts_buffer_size = 0;
            Gee.ArrayList<Models.SerializableTextTag> tag_stack = new Gee.ArrayList<Models.SerializableTextTag> ();

            Gtk.TextIter cursor;
            buffer.get_start_iter (out cursor);
            long counter = 0;

            // Scan the buffer and build tags lists and plain text buffer
            while (!cursor.is_end ()) {
                if (cursor.starts_tag (null)) {
                    cursor.get_toggled_tags (true).@foreach (i => {
                        // Only serialize non-anonymous tags, and only tags that can be found in this
                        // buffer's tag table
                        if (i.name != null && buffer.tag_table.lookup (i.name) != null) {
                            var the_tag = new Models.SerializableTextTag (i.name, counter, counter, tag_stack.size);
                            tag_stack.add (the_tag);
                            serialized_buffer.append (the_tag.tag_open ());
                        }
                    });
                }
                serialize_check_closing_tags (counter, serialized_buffer, cursor, tag_stack);

                // Append the character verbatim
                serialized_buffer.append_unichar (cursor.get_char ());

                cursor.forward_char ();
                counter ++;
            }

            // Handle any remaining closing tags
            serialize_check_closing_tags (counter, serialized_buffer, cursor, tag_stack);

            // Serialize artifacts
            foreach (var artifact in buffer.artifacts) {
                var serialized = artifact.serialize ();
                debug (serialized.length.to_string ());
                serialized_artifacts.add (new Gee.ArrayList<uint8>.wrap (serialized));
            }

            MemoryOutputStream os = new MemoryOutputStream (null);
            DataOutputStream dos = new DataOutputStream (os);
            size_t bytes_written;

            // Write table of contents
            uint8 major_version = 1;
            uint8 minor_version = 0;
            Models.TextBufferPrelude ? prelude = Models.TextBufferPrelude () {
                major_version = major_version,
                minor_version = minor_version,
                size_of_text_buffer = serialized_buffer.str.data.length,
                size_of_artifacts_buffer = artifacts_buffer_size
            };
            Utils.Streams.write_prelude (dos, prelude);

            // Write the actual content of the buffer
            if (serialized_buffer.len > 0) {
                dos.write_all (serialized_buffer.data, out bytes_written);
            }

            // Write artifacts
            for (var i = 0; i < serialized_artifacts.size; i++) {
                var item = serialized_artifacts.@get (i);
                dos.write_all (item.to_array (), out bytes_written);
            }

            dos.close ();

            uint8[] data = os.steal_data ();
            data.length = (int) os.get_data_size ();
            debug ("Serialized data lenght in bytes: %lu", data.length);

            return data;
        }

        private void serialize_check_closing_tags (
            long counter,
            StringBuilder buffer,
            Gtk.TextIter cursor,
            Gee.ArrayList<Models.SerializableTextTag> tag_stack
        ) {
            if (cursor.ends_tag (null)) {
                var closed_tags = cursor.get_toggled_tags (false);
                while (
                    closed_tags.length () != 0
                ) {
                    // Get the current closing tag from the list, remove it from the list...
                    var len = closed_tags.length ();
                    var closed_tag = closed_tags.nth_data (len - 1);
                    closed_tags.remove (closed_tag);

                    if (tag_stack != null && !tag_stack.is_empty) {
                        // ... and pop it from the stack
                        Models.SerializableTextTag tag_to_close = tag_stack.remove_at (tag_stack.size - 1);

                        if (tag_to_close != null) {
                            tag_to_close.end = counter;
                            buffer.append (tag_to_close.tag_close ());
                        } else {
                            warning ("Could not pop tag to close from the stack");
                        }
                    } else {
                        warning ("Be aware that the tag stack is null or zero sized when trying to pop an item.
                        This is probably an error because this is called when an iter is closing some tag that
                        should be present on the stack.");
                    }
                }
            }
        }
    }
}
