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
    public class FootNote : Models.TextChunkArtifact {

        public override string name {
            get {
                return "foot_note";
            }
        }

        public Gtk.TextBuffer content_buffer;

        public FootNote (Models.TextBuffer parent_buffer, int start_offset, int end_offset = -1) {
            Object (
                parent_buffer: parent_buffer,
                start_iter_offset: start_offset,
                end_iter_offset: end_offset
            );
        }

        construct {
            content_buffer = new Gtk.TextBuffer (new Manuscript.Models.XManuscriptTagTable ());
        }

        public override uint8[] serialize () throws IOError {
            var len = (sizeof (int) * 2) + name.data.length + content_buffer.text.data.length + 2;
            uint8[] buf = new uint8[1];
            buf.length = (int) len;
            MemoryOutputStream mos = new MemoryOutputStream (buf);
            DataOutputStream os = new DataOutputStream (mos);
            os.put_string (name);
            os.put_byte ('\0');
            os.put_int32 (start_iter_offset);
            os.put_int32 (end_iter_offset);
            size_t bytes_written;
            os.write_all (content_buffer.text.data, out bytes_written);
            os.put_byte ('\0');
            os.close ();
            var data = mos.steal_data ();
            data.length = (int) mos.get_data_size ();
            return data;
        }

        public FootNote.from_data (TextBuffer parent_buffer, uint8[] data) throws IOError {
            MemoryInputStream min = new MemoryInputStream.from_data (data);
            DataInputStream @in = new DataInputStream (min);
            var name = Utils.Streams.read_until (@in, '\0');
            assert ((string) name == "foot_note");

            var start_offset = @in.read_int32 ();
            var end_offset = @in.read_int32 ();

            //  var count = data.length - (int) (sizeof (int) * 2);
            //  uint8[] text_data = new uint8[count];
            //  //  text_data.length = data.length - (int) (sizeof (int) * 2);
            //  @in.read_all (text_data, out bytes_read);
            var text_data = Utils.Streams.read_until (@in, '\0');
            @in.close ();

            this (parent_buffer, start_offset, end_offset);
            content_buffer.set_text ((string) text_data, text_data.length);
            //  FootNote item = new FootNote (parent_chunk, start_offset, end_offset);
            //  item.content_buffer.set_text ((string) text_data, text_data.length);
        }
    }
}
