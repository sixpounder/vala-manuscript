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

    public struct TextBufferPrelude {
        uint8 major_version;
        uint8 minor_version;
        uint64 size_of_text_buffer;
        uint64 size_of_artifacts_buffer;
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
             * - AND THIS THING IS REMOVED FROM GTK4. FU**.
             *
             * After carefully thinking about it (aka lot of prophanities and alcohol) I decided
             * to implement a custom serializer / deserializer because we can't have nice things.
             */

            if (dirty) { // Serialize only if needed
                raw_content = new Lib.TextBufferSerializer ().serialize (this);
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
                minor_version = dis.read_byte (),
                size_of_text_buffer = dis.read_uint64 (),
                size_of_artifacts_buffer = dis.read_uint64 ()
            };

            debug ("Buffer version: %i.%i", prelude.major_version, prelude.minor_version);
            debug ("Declared size of text buffer: %s bytes", prelude.size_of_text_buffer.to_string ());
            debug ("Declared size of artifacts buffer: %s bytes", prelude.size_of_artifacts_buffer.to_string ());

            // A raw_content to be deserialized must be at least the size of its prelude
            if (raw_content.length < prelude_size) {
                warning (
                    "Raw content length (%i) is less than prelude size (%l). This might indicate a malformed chunk",
                    raw_content.length,
                    prelude_size
                );
            }

            var data = dis.read_bytes ((size_t) prelude.size_of_text_buffer);

            // One null terminators after text buffer
            //  dis.read_bytes (1);

            // Additional stuff...

            // Close the stream
            dis.close ();

            Lib.RichTextParser parser = new Lib.RichTextParser (this);
            parser.parse ((string) data.get_data ());

            dirty = false;

            connect_events ();
        }
    }
}
