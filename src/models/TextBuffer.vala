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
        private bool dirty = false;
        private uint8[] raw_content;

        public TextBuffer () {
            Object (
                tag_table: new XManuscriptTagTable ()
            );
        }

        construct {
            serialize_atom = register_serialize_tagset ("x-manuscript");
            deserialize_atom = register_deserialize_tagset ("x-manuscript");

            connect_events ();
        }

        private void connect_events () {
            changed.connect (on_buffer_changed);
            apply_tag.connect (on_buffer_changed);
            remove_tag.connect (on_buffer_changed);
        }

        private void diconnect_events () {
            changed.disconnect (on_buffer_changed);
            apply_tag.disconnect (on_buffer_changed);
            remove_tag.disconnect (on_buffer_changed);
        }

        public Gdk.Atom get_manuscript_serialize_format () {
            return serialize_atom;
        }

        public Gdk.Atom get_manuscript_deserialize_format () {
            return deserialize_atom;
        }

        private void on_buffer_changed () {
            dirty = true;
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

            // Serialize only if needed
            if (dirty) {
                Gtk.TextIter start, end;
                get_start_iter (out start);
                get_end_iter (out end);
                raw_content = serialize_x_manuscript (start, end);
                dirty = false;
            }

            return raw_content;
        }

        public void deserialize_manuscript (uint8[] raw_content) throws Error {
            this.raw_content = raw_content;

            diconnect_events ();

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

            Lib.RichTextParser parser = new Lib.RichTextParser (this);
            parser.parse ((string) data);

            dirty = false;

            connect_events ();
        }

        private uint8[] serialize_x_manuscript (Gtk.TextIter start, Gtk.TextIter end) throws IOError {
            StringBuilder buffer = new StringBuilder ();

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
                serialize_check_closing_tags (counter, buffer, cursor, tag_stack);

                // Append the character verbatim
                buffer.append_unichar (cursor.get_char ());


                cursor.forward_char ();
                counter ++;
            }

            serialize_check_closing_tags (counter, buffer, cursor, tag_stack);

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
