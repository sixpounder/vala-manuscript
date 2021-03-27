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

    //  public DocumentChunk from_archive_entry (Archive.Entry entry) {}
    //  public interface Searchable : Object {
    //      public virtual async Protocols.SearchResult[] search (string hint) {
    //          return {};
    //      }
    //  }

    public static DocumentChunk chunk_from_json_object (Json.Object obj, Document document) {
        assert (obj != null);
        assert (document != null);
        assert (obj.has_member ("chunk_type"));

        Models.ChunkType kind = (Models.ChunkType) obj.get_int_member ("chunk_type");

        switch (kind) {
            case Models.ChunkType.CHAPTER:
                return ChapterChunk.from_json_object (obj, document);
            case Models.ChunkType.CHARACTER_SHEET:
                return CharacterSheetChunk.from_json_object (obj, document);
            case Models.ChunkType.NOTE:
                return NoteChunk.from_json_object (obj, document);
            case Models.ChunkType.COVER:
                return CoverChunk.from_json_object (obj, document);
            default:
                assert_not_reached ();
        }
    }

    public interface DocumentChunk : Object, Archivable {
        public virtual signal void changed () {}

        public abstract bool broken { get; set; }
        public abstract weak Document parent_document { get; protected set; }
        public abstract int64 index { get; set; }
        public abstract ChunkType kind { get; protected set; }
        public abstract string title { get; set; }
        public abstract bool has_changes { get; protected set; }
        public abstract string uuid { get; set; }
        public abstract bool locked { get; set; }

        public static DocumentChunk new_for_document (Document document, ChunkType kind) {
            DocumentChunk new_chunk;
            switch (kind) {
                case Models.ChunkType.CHAPTER:
                    new_chunk = new ChapterChunk.empty ();
                    break;
                case Models.ChunkType.CHARACTER_SHEET:
                    new_chunk = new CharacterSheetChunk.empty ();
                    break;
                case Models.ChunkType.NOTE:
                    new_chunk = new NoteChunk.empty ();
                    break;
                case Models.ChunkType.COVER:
                    new_chunk = new CoverChunk.empty ();
                    break;
                default:
                    assert_not_reached ();
            }

            new_chunk.parent_document = document;

            return new_chunk;
        }

        public static DocumentChunk deserialize_chunk_base (Json.Object obj, Document parent) {
            DocumentChunk chunk
                = DocumentChunk.new_for_document (parent, (Models.ChunkType) obj.get_int_member ("chunk_type"));
            if (obj.has_member ("uuid")) {
                chunk.uuid = obj.get_string_member ("uuid");
            } else {
                info ("Chunk has no uuid, generating one now");
                chunk.uuid = GLib.Uuid.string_random ();
            }

            if (obj.has_member ("locked")) {
                chunk.locked = obj.get_boolean_member ("locked");
            } else {
                chunk.locked = false;
            }

            if (obj.has_member ("title")) {
                chunk.title = obj.get_string_member ("title");
            } else {
                chunk.title = _("Untitled");
            }

            if (obj.has_member ("index")) {
                chunk.index = obj.get_int_member ("index");
            } else {
                chunk.index = 0;
            }

            chunk.kind = (Models.ChunkType) obj.get_int_member ("chunk_type");

            return chunk;
        }

        public static async DocumentChunk deserialize_chunk_base_from_data (uint8[] data, Document parent)
        throws DocumentError {    
            var parser = new Json.Parser ();
            try {
                parser.load_from_stream (new MemoryInputStream.from_data (data, null), null);
                var root_object = parser.get_root ().get_object ();
                return Models.chunk_from_json_object (root_object, parent);
            } catch (Error error) {
                throw new DocumentError.PARSE (@"Cannot parse manuscript file: $(error.message)");
            }
        }

        public abstract Json.Object to_json_object ();
    }

    public abstract class DocumentChunkBase : Object, Archivable, DocumentChunk {
        public virtual bool broken { get; protected set; }
        public virtual int64 index { get; set; }
        public virtual ChunkType kind { get; protected set; }
        public virtual string title { get; set; }
        public virtual bool has_changes { get; protected set; }
        public virtual string uuid { get; set; }
        public virtual bool locked { get; set; }
        public virtual weak Document parent_document { get; protected set; }

        public virtual Json.Object to_json_object () {
            var node = new Json.Object ();
            node.set_string_member ("uuid", uuid);
            node.set_int_member ("index", index);
            node.set_int_member ("chunk_type", (int64) kind);
            node.set_string_member ("title", title);
            node.set_boolean_member ("locked", locked);

            return node;
        }

        public virtual Gee.Collection<ArchivableItem> to_archivable_entries () {
            Json.Generator gen = new Json.Generator ();
            var root = new Json.Node (Json.NodeType.OBJECT);
            root.set_object (to_json_object ());
            gen.set_root (root);
            var c = new Gee.ArrayList<ArchivableItem> ();
            var item = new ArchivableItem ();
            item.name = @"$uuid.json";
            item.data = gen.to_data (null).data;

            c.add (item);

            return c;
        }

        public virtual Archivable from_archive_entries (Gee.Collection<ArchivableItem> entries) {
            return this;
        }
    }

    public abstract class TextChunkBase : DocumentChunkBase, Archivable {
        public virtual signal void undo_queue_drain () {}
        public virtual signal void undo () {}
        public virtual signal void redo () {}
        public virtual signal void analyze () {}

        protected uchar[] raw_content;
        public virtual uint words_count { get; protected set; }
        public virtual double estimate_reading_time { get; protected set; }
        public virtual string content_ref { get; protected set; }

        public virtual Models.TextBuffer buffer { get; protected set; }

        public uchar[] get_raw () {
            return raw_content;
        }

        public void set_raw (uchar[] value) {
            raw_content = value;
        }

        public override Json.Object to_json_object () {
            var node = base.to_json_object ();
            node.set_string_member ("content_ref", @"$uuid.text");
            return node;
        }

        public new virtual Gee.Collection<ArchivableItem> to_archivable_entries () {
            Json.Generator gen = new Json.Generator ();
            var root = new Json.Node (Json.NodeType.OBJECT);
            root.set_object (to_json_object ());
            gen.set_root (root);

            var c = new Gee.ArrayList<ArchivableItem> ();
            var item = new ArchivableItem ();
            item.name = @"$uuid.json";
            item.group = kind.to_string ();
            item.data = gen.to_data (null).data;

            var atom = buffer.get_manuscript_serialize_format ();
            Gtk.TextIter start, end;
            buffer.get_start_iter (out start);
            buffer.get_end_iter (out end);
            uint8[] serialized_data = buffer.serialize (buffer, atom, start, end);
            debug (@"$(serialized_data.length) bytes of text");
            var text_item = new ArchivableItem.with_props (@"$uuid.text", "Resource", serialized_data);

            c.add (item);
            c.add (text_item);

            return c;
        }

        protected abstract void build_buffer ();
        public virtual void load_text_data (uint8[] data) {
            set_raw (data);
            build_buffer ();
        }
    }
}
