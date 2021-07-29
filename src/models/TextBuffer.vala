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
    struct TextTag {
        string name;
        long start;
        long end;
    }

    struct TextBufferPrelude {
        uint8 major_version;
        uint8 minor_version;
        uint64 size_of_tag_map;
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
            size_t text_tag_size = sizeof (TextTag);

            InputStream @is = new MemoryInputStream.from_data (raw_content);
            DataInputStream dis = new DataInputStream (@is);
            TextBufferPrelude prelude = TextBufferPrelude () {
                major_version = dis.read_byte (),
                minor_version = dis.read_byte (),
                size_of_tag_map = (uint64) dis.read_uint64 ()
            };

            // A raw_content to be deserialized must be at least the size of its prelude
            assert (raw_content.length >= prelude_size);

            MemoryOutputStream content_buffer = new MemoryOutputStream.resizable ();
            //  SList<TextTag?> tag_list = new SList<TextTag> ();
            uint8 buffer[1];
            while (true) {
                dis.read (buffer);
                if (buffer[0] == '\0') {
                    break;
                } else {
                    content_buffer.write (buffer);
                }
            }

            content_buffer.close ();
            var data = content_buffer.steal_data ();
            data.length = (int) content_buffer.get_data_size ();
            set_text ((string) data);

            dis.close ();

            //  if (prelude.size_of_tag_map > 0) {
            //      TextTag* tag_definition_ptr = (TextTag *)raw_content[prelude_size];
            //      ulong tag_map_b_counter = 0;
            //      while (tag_map_b_counter < prelude.size_of_tag_map) {
            //          tag_list.append (*tag_definition_ptr);
            //          tag_map_b_counter += text_tag_size;
            //          tag_definition_ptr += text_tag_size;
            //      }
            //  }

            //  if (prelude.size_of_content > 0) {
            //      unichar* char_ptr = (unichar*) raw_content[prelude_size + prelude.size_of_tag_map];
            //      ulong content_byte_counter = 0;
            //      while (content_byte_counter < prelude.size_of_content) {
            //          content_buffer.append_unichar (*char_ptr);
            //          char_ptr += sizeof (unichar);
            //          content_byte_counter += 1;
            //      }

            //      set_text (content_buffer.str);
            //  }

            // TODO: apply tags
        }

        private uint8[] serialize_x_manuscript (Gtk.TextIter start, Gtk.TextIter end) throws Error {
            StringBuilder buffer = new StringBuilder ();
            SList<TextTag?> tag_map = new SList<TextTag> ();
            Gee.ArrayList<TextTag?> tag_stack = new Gee.ArrayList<TextTag?> ();

            Gtk.TextIter cursor;
            get_start_iter (out cursor);
            long counter = 0;

            while (!cursor.is_end ()) {
                if (cursor.starts_tag (null)) {
                    cursor.get_toggled_tags (true).@foreach (i => {
                        // Only serialize non-anonymous tags, and only tags that can be found in this
                        // buffer's tag table
                        if (i.name != null && tag_table.lookup (i.name) != null) {
                            var the_tag = TextTag () {
                                name = i.name,
                                start = counter,
                                end = counter
                            };
                            tag_stack.add (the_tag);
                            //  buffer.append (open_tag_str (i));
                        }
                    });
                }
                
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
                        TextTag tag_to_close = tag_stack.remove_at (tag_stack.size - 1);
                        tag_to_close.end = counter;

                        // Add the tag to the map that will be saved along with the text buffer
                        tag_map.append (tag_to_close);
                    }
                }
                // Append the character verbatim
                buffer.append_unichar (cursor.get_char ());
                cursor.forward_char ();
                counter ++;
            }

            uint8[] tag_map_buffer = new uint8[sizeof (TextTag) * tag_map.length ()];
            uint8* ptr = tag_map_buffer;

            tag_map.@foreach (tag => {
                *ptr = (uint8[]) tag;
                ptr += sizeof (TextTag);
            });

            // Write table of contents
            TextBufferPrelude prelude = TextBufferPrelude () {
                major_version = 1,
                minor_version = 0,
                size_of_tag_map = tag_map.length () * sizeof (TextTag)
            };

            MemoryOutputStream os = new MemoryOutputStream (null, GLib.realloc, GLib.free);
            DataOutputStream dos = new DataOutputStream (os);
            size_t bytes_written;
            //  dos.write_all ((uint8[]) prelude, out bytes_written);
            dos.put_byte (prelude.major_version);
            dos.put_byte (prelude.minor_version);
            dos.put_uint64 (prelude.size_of_tag_map);

            if (tag_map_buffer.length > 0) {
                dos.write_all (tag_map_buffer, out bytes_written);
            }
            if (buffer.len > 0) {
                dos.write_all (buffer.data, out bytes_written);
            }
            dos.put_byte ('\0');
            dos.close ();
            uint8[] data = os.steal_data ();
            data.length = (int) os.get_data_size ();
            return data;
        }
    }
}
