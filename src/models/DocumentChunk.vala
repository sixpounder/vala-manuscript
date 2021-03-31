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

    public abstract class DocumentChunk : Object, Archivable {
        public virtual signal void changed () {}

        public virtual weak Document parent_document { get; protected set; }
        public virtual bool broken { get; set; }
        public virtual int64 index { get; set; }
        public virtual ChunkType kind { get; protected set; }
        public virtual string title { get; set; }
        public virtual string uuid { get; set; }
        public virtual bool locked { get; set; }
        public virtual bool has_changes { get; internal set; }

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

        public static DocumentChunk new_from_json_object (Json.Object obj, Document parent) {
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

        public static async DocumentChunk new_from_data (uint8[] data, Document parent)
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
    }

    public abstract class TextChunk : DocumentChunk, Archivable {
        protected Services.AppSettings settings = Services.AppSettings.get_default ();
        protected uint words_counter_timer = 0;

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

        public override Gee.Collection<ArchivableItem> to_archivable_entries () {
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

        public virtual void load_buffer_data (uint8[] data) {
            set_raw (data);
        }

        public virtual void create_buffer (uint8[]? data = null) {
            buffer = new Models.TextBuffer (new DocumentTagTable ());
            buffer.highlight_matching_brackets = false;
            buffer.max_undo_levels = -1;
            buffer.highlight_syntax = false;

            try {
                var raw_content = data;
                if (raw_content.length != 0) {
                    buffer.begin_not_undoable_action ();
                    Gtk.TextIter start;
                    buffer.get_start_iter (out start);
                    buffer.deserialize (buffer, buffer.get_manuscript_deserialize_format (), start, raw_content);
                    buffer.end_not_undoable_action ();
                }
            } catch (Error e) {
                warning (e.message);
                broken = true;
            }

            words_count = Utils.Strings.count_words (buffer.text);
            estimate_reading_time = Utils.Strings.estimate_reading_time (words_count);

            buffer.changed.connect (on_content_changed);
            buffer.undo.connect (on_buffer_undo);
            buffer.redo.connect (on_buffer_redo);

            buffer.insert_text.connect (text_inserted);
            buffer.delete_range.connect (range_deleted);

            buffer.undo_manager.can_undo_changed.connect (on_can_undo_changed);
            buffer.undo_manager.can_redo_changed.connect (on_can_redo_changed);

            settings.change.connect (() => {
                set_buffer_scheme ();
            });

            set_buffer_scheme ();
        }

        protected void set_buffer_scheme () {
            var scheme = settings.prefer_dark_style ? "manuscript-dark" : "manuscript-light";
            var style_manager = Gtk.SourceStyleSchemeManager.get_default ();
            var style = style_manager.get_scheme (scheme);
            buffer.style_scheme = style;
        }

        protected void text_inserted () {
        }

        protected void range_deleted () {
        }

        protected void on_can_undo_changed () {
            if (buffer.can_undo) {
                has_changes = true;
                changed ();
            } else {
                has_changes = false;
            }
        }

        protected void on_can_redo_changed () {
            changed ();
        }

        protected void on_buffer_redo () {
            redo ();
        }

        protected void on_buffer_undo () {
            undo ();
            if (!buffer.undo_manager.can_undo () ) {
                undo_queue_drain ();
            }
        }

        /**
         * Emit content_changed event to listeners
         */
        protected void on_content_changed () {
            if (words_counter_timer != 0) {
                GLib.Source.remove (words_counter_timer);
            }

            // Count words every 200 milliseconds to avoid thrashing the CPU
            words_counter_timer = Timeout.add (200, () => {
                words_counter_timer = 0;
                //  words_count = Utils.Strings.count_words (buffer.text);
                //  estimate_reading_time = Utils.Strings.estimate_reading_time (words_count);
                var analyze_task = new AnalyzeTask (buffer.text);
                analyze_task.done.connect ((analyze_result) => {
                    words_count = analyze_result.words_count;
                    estimate_reading_time = analyze_result.estimate_reading_time;
                    analyze ();
                });
                Services.ThreadPool.get_default ().add (analyze_task);
                return false;
            });

            changed ();
        }

        ~ TextChunk () {
            if (buffer != null) {
                debug ("Disposing TextChunkInstance");
                buffer.changed.disconnect (on_content_changed);
                buffer.undo.disconnect (on_buffer_undo);
                buffer.redo.disconnect (on_buffer_redo);
                buffer.insert_text.disconnect (text_inserted);
                buffer.delete_range.disconnect (range_deleted);
                buffer.undo_manager.can_undo_changed.disconnect (on_can_undo_changed);
                buffer.undo_manager.can_redo_changed.disconnect (on_can_redo_changed);
            }
        }
    }
}
