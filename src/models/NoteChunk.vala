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
    public class NoteChunk : TextChunk {
        public NoteChunk.empty () {
            uuid = GLib.Uuid.string_random ();
            title = _("New note");
            kind = ChunkType.NOTE;
            set_raw ({});
        }

        public static NoteChunk from_json_object (Json.Object obj, Document document) {
            NoteChunk self = (NoteChunk) DocumentChunk.new_from_json_object (obj, document);

            if (obj.has_member ("raw_content")) {
                self.set_raw (Base64.decode (obj.get_string_member ("raw_content")));
            } else {
                self.set_raw ({});
            }

            //  self.create_buffer ();

            return self;
        }

        public override Json.Object to_json_object () {
            var node = base.to_json_object ();
            //  node.set_string_member ("raw_content", buffer.text);

            return node;
        }
    }
}
