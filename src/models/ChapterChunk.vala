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
    public class ChapterChunk : TextChunk, Archivable {
        public string notes { get; set; }

        public new void set_raw (uchar[] value) {
            base.raw_content = value;
        }

        public ChapterChunk.empty () {
            uuid = GLib.Uuid.string_random ();
            title = _("New chapter");
            kind = ChunkType.CHAPTER;
            set_raw ({});

            //  create_buffer ();
        }

        public static ChapterChunk from_json_object (Json.Object obj, Document document) {
            ChapterChunk self = (ChapterChunk) DocumentChunk.new_from_json_object (obj, document);

            if (obj.has_member ("raw_content")) {
                self.set_raw (Base64.decode (obj.get_string_member ("raw_content")));
            } else {
                self.set_raw ({});
            }

            if (obj.has_member ("notes")) {
                self.notes = obj.get_string_member ("notes");
            } else {
                self.notes = null;
            }

            //  self.create_buffer ();

            return self;
        }

        public override Gee.Collection<ArchivableItem> to_archivable_entries () {
            return base.to_archivable_entries ();
        }

        //  ~ ChapterChunk () {
        //      if (buffer != null) {
        //          buffer.changed.disconnect (on_content_changed);
        //          buffer.undo.disconnect (on_buffer_undo);
        //          buffer.redo.disconnect (on_buffer_redo);
        //          buffer.insert_text.disconnect (text_inserted);
        //          buffer.delete_range.disconnect (range_deleted);
        //          buffer.undo_manager.can_undo_changed.disconnect (on_can_undo_changed);
        //          buffer.undo_manager.can_redo_changed.disconnect (on_can_redo_changed);
        //          if (buffer.ref_count > 0) {
        //              buffer.unref ();
        //          }
        //      }
        //  }

        public override Json.Object to_json_object () {
            var node = base.to_json_object ();
            node.set_string_member ("notes", notes);

            return node;
        }
    }
}
