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
    public class NoteChunk : TextChunkBase {
        protected uint words_counter_timer = 0;

        public NoteChunk.empty () {
            uuid = GLib.Uuid.string_random ();
            title = _("New note");
            kind = ChunkType.NOTE;
            build_buffer ();
        }

        public static NoteChunk from_json_object (Json.Object obj, Document document) {
            NoteChunk self = (NoteChunk) DocumentChunk.deserialize_chunk_base (obj, document);

            if (obj.has_member ("raw_content")) {
                self.set_raw (Base64.decode (obj.get_string_member ("raw_content")));
            } else {
                self.set_raw ({});
            }

            self.build_buffer ();

            return self;
        }

        public override Json.Object to_json_object () {
            var node = base.to_json_object ();
            node.set_string_member ("raw_content", buffer.text);

            return node;
        }

        protected override void build_buffer () {

            buffer = new Models.TextBuffer (new DocumentTagTable () );
            buffer.highlight_matching_brackets = false;
            buffer.max_undo_levels = -1;
            buffer.highlight_syntax = false;

            try {
                var raw_content = get_raw ();
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
        }

        private void on_can_undo_changed () {
            if (buffer.can_undo) {
                has_changes = true;
                changed ();
            } else {
                has_changes = false;
            }
        }

        private void on_can_redo_changed () {
            changed ();
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

        private void text_inserted () {
        }

        private void range_deleted () {
        }
    }
}
