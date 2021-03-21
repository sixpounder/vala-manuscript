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
    public class ChapterChunk : TextChunkBase {
        protected Services.AppSettings settings = Services.AppSettings.get_default ();
        protected uint words_counter_timer = 0;
        public string notes { get; set; }

        protected string _title;
        public new string title {
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

        public ChapterChunk.empty () {
            uuid = GLib.Uuid.string_random ();
            title = _("New chapter");
            kind = ChunkType.CHAPTER;
            raw_content = "";

            build_buffer ();
        }

        public static ChapterChunk from_json_object (Json.Object obj, Document document) {
            ChapterChunk self = (ChapterChunk) DocumentChunk.deserialize_chunk_base (obj, document);

            if (obj.has_member ("raw_content")) {
                self.raw_content = obj.get_string_member ("raw_content");
            } else {
                self.raw_content = "";
            }

            if (obj.has_member ("notes")) {
                self.notes = obj.get_string_member ("notes");
            } else {
                self.notes = null;
            }

            self.build_buffer ();

            return self;
        }

        public override Json.Object to_json_object () {
            var root = base.to_json_object ();
            root.set_string_member ("raw_content", buffer.text);
            root.set_string_member ("notes", notes);

            return root;
        }

        protected void build_buffer () {

            buffer = new Gtk.SourceBuffer (new DocumentTagTable () );
            buffer.highlight_matching_brackets = false;
            buffer.max_undo_levels = -1;
            buffer.highlight_syntax = false;

            buffer.begin_not_undoable_action ();
            buffer.set_text (raw_content, raw_content.length);
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

            settings.change.connect (() => {
                set_buffer_scheme ();
            });

            set_buffer_scheme ();
        }

        private void set_buffer_scheme () {
            var scheme = settings.desktop_prefers_dark_theme ? "manuscript-dark" : "manuscript-light";
            var style_manager = Gtk.SourceStyleSchemeManager.get_default ();
            var style = style_manager.get_scheme (scheme);
            buffer.style_scheme = style;
        }

        private void text_inserted () {
        }

        private void range_deleted () {
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
    }
}
