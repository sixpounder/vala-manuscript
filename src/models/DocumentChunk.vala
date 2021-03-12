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

    public class DocumentChunk : Object {

        protected const string[] SERIALIZABLE_PROPERIES = {
            "notes",
            "raw_content",
            "index",
            "chunk_type"
        };

        public signal void change ();
        public signal void undo_queue_drain ();
        public signal void undo ();
        public signal void redo ();
        public signal void analyze ();

        protected uint words_counter_timer = 0;
        public virtual ChunkType kind { get; set; }
        public bool has_changes { get; private set; }
        public uint words_count { get; private set; }
        public double estimate_reading_time { get; private set; }
        public string notes { get; set; }
        public string raw_content { get; set; }
        public int64 index { get; set; }
        public string uuid { get; set; }

        protected string _title;
        public string title {
            get {
                return _title;
            }
            set {
                assert (value != null);
                if (value != "") {
                    _title = value;
                }
            }
        }

        protected Gtk.SourceBuffer _buffer;
        public Gtk.SourceBuffer buffer {
            get {
                return _buffer;
            }

            private set {
                _buffer = value;
            }
        }

        public DocumentChunk.empty (ChunkType kind) {
            Object (
                kind: kind,
                uuid: GLib.Uuid.string_random ()
            );
            switch (kind) {
                case ChunkType.CHAPTER:
                    title = _("New chapter");
                    break;
                case ChunkType.CHARACTER_SHEET:
                    title = _("New character sheet");
                    break;
                case ChunkType.NOTE:
                    title = _("New note");
                    break;
                default:
                    assert_not_reached ();
            }
            build_buffer ();
        }

        public DocumentChunk.from_json_object (Json.Object obj) {
            assert (obj != null);
            if (obj.has_member ("uuid")) {
                uuid = obj.get_string_member ("uuid");
            } else {
                info ("Chunk has no uuid, generating one now");
                uuid = GLib.Uuid.string_random ();
            }

            if (obj.has_member ("raw_content")) {
                raw_content = obj.get_string_member ("raw_content");
            } else {
                raw_content = "";
            }

            if (obj.has_member ("notes")) {
                notes = obj.get_string_member ("notes");
            } else {
                notes = null;
            }

            title = obj.get_string_member ("title");

            if (obj.has_member ("index")) {
                index = obj.get_int_member ("index");
            } else {
                index = 0;
            }

            kind = (Models.ChunkType) obj.get_int_member ("chunk_type");
            build_buffer (raw_content);
        }

        public Json.Object to_json_object () {
            var root = new Json.Object ();
            root.set_string_member ("uuid", uuid);
            root.set_string_member ("raw_content", buffer.text);
            root.set_string_member ("title", title);
            root.set_string_member ("notes", notes);
            root.set_int_member ("index", index);
            root.set_int_member ("chunk_type", (int64) kind);

            return root;
        }

        protected void build_buffer (string content = "") {

            buffer = new Gtk.SourceBuffer (new DocumentTagTable () );
            buffer.highlight_matching_brackets = false;
            buffer.max_undo_levels = -1;
            buffer.highlight_syntax = false;

            buffer.begin_not_undoable_action ();
            buffer.set_text (content, content.length);
            buffer.end_not_undoable_action ();

            words_count = Utils.Strings.count_words (buffer.text);
            estimate_reading_time = Utils.Strings.estimate_reading_time (words_count);

            buffer.changed.connect (on_content_changed);
            buffer.undo.connect (on_buffer_undo);
            buffer.redo.connect (on_buffer_redo);

            buffer.insert_text.connect (text_inserted);
            buffer.delete_range.connect (range_deleted);

            buffer.undo_manager.can_undo_changed.connect (on_can_undo_changed);
            buffer.undo_manager.can_redo_changed.connect (on_can_redo_changed);
        }

        private void text_inserted () {
        }

        private void range_deleted () {
        }

        private void on_can_undo_changed () {
            if (buffer.can_undo) {
                has_changes = true;
                change ();
            } else {
                has_changes = false;
            }
        }

        private void on_can_redo_changed () {
            change ();
        }

        private void on_buffer_redo () {
            redo ();
        }

        private void on_buffer_undo () {
            undo ();
            if (!buffer.undo_manager.can_undo () ) {
                undo_queue_drain ();
            }
        }

        /**
         * Emit content_changed event to listeners
         */
        private void on_content_changed () {
            if (words_counter_timer != 0) {
                GLib.Source.remove (words_counter_timer);
            }

            // Count words every 200 milliseconds to avoid thrashing the CPU
            this.words_counter_timer = Timeout.add (200, () => {
                words_counter_timer = 0;
                words_count = Utils.Strings.count_words (buffer.text);
                estimate_reading_time = Utils.Strings.estimate_reading_time (words_count);
                analyze ();
                return false;
            });

            change ();
        }
    }
}
