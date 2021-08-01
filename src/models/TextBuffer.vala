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

        public SerializableTextTag (
            string name = "anonynous",
            uint64 start = 0,
            uint64 end = 0,
            int priority = 0
        ) {
            this.name = name;
            this.start = start;
            this.end = end;
            this.priority = priority;
        }

        public string tag_open () {
            return @"<$name>";
        }

        public string tag_close () {
            return @"</$name>";
        }

        //  public size_t get_bytes_length () {
        //      return (sizeof (uint64) * 3) + (name.length * sizeof (uint8)) + sizeof (int32);
        //      //     ^ header, start, end     ^ length of the name string     ^ priority
        //  }

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

        //  public static SerializableTextTag from_reader (InputStream stream) throws Error {
        //      assert (!stream.is_closed ());
        //      DataInputStream dis = new DataInputStream (stream);
        //      size_t bytes_read;
        //      var obj = new SerializableTextTag ();
        //      var expected_name_length = dis.read_uint64 ();
        //      uint8[] name_buffer = new uint8[expected_name_length];
        //      dis.read_all (name_buffer, out bytes_read);
        //      obj.name = (string)name_buffer;
        //      assert (obj.name.length == expected_name_length);
        //      obj.start = dis.read_uint64 ();
        //      obj.end = dis.read_uint64 ();
        //      obj.priority = dis.read_int32 ();

        //      return obj;
        //  }
    }

    struct TextBufferPrelude {
        uint8 major_version;
        uint8 minor_version;
        //  uint64 size_of_tag_map;
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

        public new uint8[] serialize () throws IOError {
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

            Gtk.TextIter start, end;
            get_start_iter (out start);
            get_end_iter (out end);

            return serialize_x_manuscript (start, end);
        }

        public void deserialize_manuscript (uint8[] raw_content) throws Error {
            size_t prelude_size = sizeof (TextBufferPrelude);

            InputStream @is = new MemoryInputStream.from_data (raw_content);
            DataInputStream dis = new DataInputStream (@is);
            TextBufferPrelude prelude = TextBufferPrelude () {
                major_version = dis.read_byte (),
                minor_version = dis.read_byte ()
            };

            debug ("Buffer version: %i.%i", prelude.major_version, prelude.minor_version);

            // A raw_content to be deserialized must be at least the size of its prelude
            assert (raw_content.length >= prelude_size);

            var data = read_until (dis);
            dis.close ();

            set_text ("");
            Gtk.TextIter start;
            get_start_iter (out start);
            insert_markup (ref start, (string) data, data.length);

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
                            buffer.append (the_tag.tag_open ());
                        }
                    });
                }

                // Append the character verbatim
                buffer.append_unichar (cursor.get_char ());

                serialize_check_closing_tags (counter, buffer, cursor, tag_stack);

                cursor.forward_char ();
                counter ++;
            }

            // Check if the last iter closes some tags
            //  serialize_check_closing_tags (counter, buffer, cursor, tag_stack);

            // Serialize the tags into a byte buffer
            MemoryOutputStream tag_map_stream = new MemoryOutputStream (null, GLib.realloc, GLib.free);
            size_t tag_bytes_written = 0;
            size_t tag_total_bytes = 0;

            tag_map.@foreach (tag => {
                try {
                    tag_map_stream.write_all (tag.serialize (), out tag_bytes_written);
                } catch (IOError err) {
                    critical (err.message);
                }
                tag_total_bytes += tag_bytes_written;
            });
            tag_map_stream.close ();
            var tags_data = tag_map_stream.steal_data ();
            tags_data.length = (int) tag_map_stream.get_data_size ();

            // Write table of contents
            TextBufferPrelude prelude = TextBufferPrelude () {
                major_version = 1,
                minor_version = 0
                //  size_of_tag_map = tag_total_bytes
            };

            MemoryOutputStream os = new MemoryOutputStream (null, GLib.realloc, GLib.free);
            DataOutputStream dos = new DataOutputStream (os);
            size_t bytes_written;

            dos.put_byte (prelude.major_version);
            dos.put_byte (prelude.minor_version);

            //  if (tags_data.length > 0) {
            //      dos.write_all (tags_data, out bytes_written);
            //  }

            // Write the actual content of the buffer
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
            StringBuilder buffer,
            Gtk.TextIter cursor,
            Gee.ArrayList<SerializableTextTag> tag_stack
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
                        SerializableTextTag tag_to_close = tag_stack.remove_at (tag_stack.size - 1);

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
