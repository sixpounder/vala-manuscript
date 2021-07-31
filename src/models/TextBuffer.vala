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
    internal class SerializableTextTag {
        //  uint64 length_header;
        public string name;
        public uint64 start;
        public uint64 end;
        public int priority;

        public SerializableTextTag (string name = "", uint64 start = 0, uint64 end = 0, int priority = 0) {
            this.name = name;
            this.start = start;
            this.end = end;
            this.priority = priority;
        }

        public size_t get_bytes_length () {
            return (sizeof (uint64) * 3) + (name.length * sizeof (uint8)) + sizeof (int32);
            //     ^ header, start, end     ^ length of the name string     ^ priority
        }

        public uint8[] serialize () throws IOError {
            MemoryOutputStream stream = new MemoryOutputStream (null);
            DataOutputStream os = new DataOutputStream (stream);

            os.put_uint64 (name.length);
            os.put_string (name);
            os.put_uint64 (start);
            os.put_uint64 (end);

            stream.close ();
            uint8[] data = stream.steal_data ();
            data.length = (int) stream.get_data_size ();

            return data;
        }

        public static SerializableTextTag from_reader (InputStream stream) throws Error {
            assert (!stream.is_closed ());
            DataInputStream dis = new DataInputStream (stream);
            size_t bytes_read;
            var obj = new SerializableTextTag ();
            var expected_name_length = dis.read_uint64 ();
            uint8[] name_buffer = new uint8[expected_name_length];
            dis.read_all (name_buffer, out bytes_read);
            obj.name = (string)name_buffer;
            assert (obj.name.length == expected_name_length);
            obj.start = dis.read_uint64 ();
            obj.end = dis.read_uint64 ();
            obj.priority = dis.read_int32 ();

            return obj;
        }
    }

    struct TextBufferPrelude {
        uint8 major_version;
        uint8 minor_version;
        uint64 size_of_tag_map;
    }

    const uint8 NULL_TERMINATOR = '\0';

    private uint8[] read_until (InputStream stream, uint8 marker = NULL_TERMINATOR) throws Error {
        MemoryOutputStream content_buffer = new MemoryOutputStream.resizable ();
        uint8 buffer[1];
        while (true) {
            stream.read (buffer);
            if (buffer[0] == '\0') {
                break;
            } else {
                content_buffer.write (buffer);
            }
        }

        content_buffer.close ();
        var data = content_buffer.steal_data ();
        data.length = (int) content_buffer.get_data_size ();

        return data;
    }

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
            //  var atom = get_manuscript_serialize_format ();
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
             * - if the user has searched anything, an __anonymous__ Gtk.TextTag is applied to search results,
             *   it gets serialized and fucks shit up when the buffer is loaded again
             * - AND THIS THING IS REMOVE FROM GTK4. FU**.
             */
            //  return serialize (this, atom, start, end);

            return serialize_x_manuscript (start, end);
        }

        public void deserialize_manuscript (uint8[] raw_content) throws Error {
            size_t prelude_size = sizeof (TextBufferPrelude);

            InputStream @is = new MemoryInputStream.from_data (raw_content);
            DataInputStream dis = new DataInputStream (@is);
            TextBufferPrelude prelude = TextBufferPrelude () {
                major_version = dis.read_byte (),
                minor_version = dis.read_byte (),
                size_of_tag_map = (uint64) dis.read_uint64 ()
            };

            // A raw_content to be deserialized must be at least the size of its prelude
            assert (raw_content.length >= prelude_size);

            if (prelude.size_of_tag_map > 0) {
                Gee.ArrayList<SerializableTextTag> tag_list = new Gee.ArrayList<SerializableTextTag> ();
                ulong tag_map_b_counter = 0;
                while (tag_map_b_counter < prelude.size_of_tag_map) {
                    var tag = SerializableTextTag.from_reader (dis);
                    tag_list.add (tag);
                    tag_map_b_counter += tag.get_bytes_length ();
                }
            }

            var data = read_until (dis);
            dis.close ();

            set_text ((string) data);

            // TODO: apply tags
        }

        private uint8[] serialize_x_manuscript (Gtk.TextIter start, Gtk.TextIter end) throws IOError {
            StringBuilder buffer = new StringBuilder ();
            SList<SerializableTextTag> tag_map = new SList<SerializableTextTag> ();
            Gee.ArrayList<SerializableTextTag> tag_stack = new Gee.ArrayList<SerializableTextTag> ();

            Gtk.TextIter cursor;
            get_start_iter (out cursor);
            long counter = 0;

            // Scan the buffer and build tags lists and plain text buffer
            while (!cursor.is_end ()) {
                if (cursor.starts_tag (null)) {
                    cursor.get_toggled_tags (true).@foreach (i => {
                        // Only serialize non-anonymous tags, and only tags that can be found in this
                        // buffer's tag table
                        if (i.name != null && tag_table.lookup (i.name) != null) {
                            var the_tag = new SerializableTextTag (i.name, counter, counter, tag_stack.size);
                            tag_stack.add (the_tag);
                        }
                    });
                }

                serialize_check_closing_tags (counter, cursor, tag_stack, tag_map);

                // Append the character verbatim
                buffer.append_unichar (cursor.get_char ());
                cursor.forward_char ();
                counter ++;
            }

            // Check if the last iter closes some tags
            serialize_check_closing_tags (counter, cursor, tag_stack, tag_map);

            // Serialize the tags into a byte buffer
            MemoryOutputStream tag_map_stream = new MemoryOutputStream (null, GLib.realloc, GLib.free);
            size_t tag_bytes_written = 0;
            size_t tag_total_bytes = 0;

            tag_map.@foreach (tag => {
                tag_map_stream.write_all (tag.serialize (), out tag_bytes_written);
                tag_total_bytes += tag_bytes_written;
            });
            tag_map_stream.close ();
            var tags_data = tag_map_stream.steal_data ();
            tags_data.length = (int) tag_map_stream.get_data_size ();

            // Write table of contents
            TextBufferPrelude prelude = TextBufferPrelude () {
                major_version = 1,
                minor_version = 0,
                size_of_tag_map = tag_total_bytes
            };

            MemoryOutputStream os = new MemoryOutputStream (null, GLib.realloc, GLib.free);
            DataOutputStream dos = new DataOutputStream (os);
            size_t bytes_written;
            //  dos.write_all ((uint8[]) prelude, out bytes_written);
            dos.put_byte (prelude.major_version);
            dos.put_byte (prelude.minor_version);
            dos.put_uint64 (prelude.size_of_tag_map);

            if (tags_data.length > 0) {
                dos.write_all (tags_data, out bytes_written);
            }

            if (buffer.len > 0) {
                dos.write_all (buffer.data, out bytes_written);
            }
            dos.put_byte (NULL_TERMINATOR);
            dos.close ();
            uint8[] data = os.steal_data ();
            data.length = (int) os.get_data_size ();
            return data;
        }

        private void serialize_check_closing_tags (
            long counter,
            Gtk.TextIter cursor,
            Gee.ArrayList<SerializableTextTag> tag_stack,
            SList<SerializableTextTag> tag_map
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

                    // ... and pop it from the stack
                    SerializableTextTag tag_to_close = tag_stack.remove_at (tag_stack.size - 1);
                    tag_to_close.end = counter;

                    // Add the tag to the map that will be saved along with the text buffer
                    tag_map.append (tag_to_close);
                }
            }
        }
    }
}
