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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Manuscript.Models {
    public delegate void ChunkTransformFunc (DocumentChunk chunk);

    public abstract class DocumentChunk : Object {
        public virtual int64 index { get; set; }
        public virtual ChunkType kind { get; protected set; }
        public virtual string title { get; set; }
        public virtual bool has_changes { get; protected set; }
        public virtual string uuid { get; set; }

        public virtual Json.Object to_json_object () {
            var node = new Json.Object ();
            node.set_string_member ("uuid", uuid);
            node.set_int_member ("index", index);
            node.set_int_member ("chunk_type", (int64) kind);
            node.set_string_member ("title", title);

            return node;
        }

        //  public DocumentChunkImpl empty_chunk (ChunkType kind) {
        //      DocumentChunkImpl impl;
        //      switch (kind) {
        //          case ChunkType.CHAPTER:
        //              impl = new ChapterChunk ();
        //              impl.title = _("New chapter");
        //              break;
        //          case ChunkType.CHARACTER_SHEET:
        //              impl = new CharacterSheetChunk ();
        //              impl.title = _("New character sheet");
        //              break;
        //          case ChunkType.NOTE:
        //              impl = new NoteChunk ();
        //              impl.title = _("New note");
        //              break;
        //          case ChunkType.COVER:
        //              impl = new CoverChunk ();
        //              impl.title = _("Cover");
        //              break;
        //          default:
        //              assert_not_reached ();
        //      }

        //      impl.uuid = GLib.Uuid.string_random ();
        //      impl.kind = kind;

        //      return impl;
        //  }

        public static DocumentChunk from_json_object (Json.Object obj) {
            assert (obj != null);
            var kind = (Models.ChunkType) obj.get_int_member ("chunk_type");

            switch (kind) {
                case Models.ChunkType.CHAPTER:
                    return new ChapterChunk.from_json_object (obj);
                case Models.ChunkType.CHARACTER_SHEET:
                    return new CharacterSheetChunk.from_json_object (obj);
                case Models.ChunkType.NOTE:
                    return new NoteChunk.from_json_object (obj);
                case Models.ChunkType.COVER:
                    return new CoverChunk.from_json_object (obj);
                default:
                    assert_not_reached ();
            }
        }
    }

    public abstract class TextChunk : DocumentChunk {
        public virtual signal void change () {}
        public virtual signal void undo_queue_drain () {}
        public virtual signal void undo () {}
        public virtual signal void redo () {}
        public virtual signal void analyze () {}

        public virtual string raw_content { get; set; }

        public virtual uint words_count { get; protected set; }
        public virtual double estimate_reading_time { get; protected set; }

        protected Gtk.SourceBuffer _buffer;
        public virtual Gtk.SourceBuffer buffer {
            get {
                return _buffer;
            }

            protected set {
                _buffer = value;
            }
        }
    }
}
