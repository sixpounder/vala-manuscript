namespace Manuscript.Models {
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
        public virtual ChunkType chunk_type { get; set; }
        public bool has_changes { get; private set; }
        public uint words_count { get; private set; }
        public double estimate_reading_time { get; private set; }
        public string notes { get; set; }
        public string raw_content { get; set; }
        public int64 index { get; set; }

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

        public DocumentChunk.empty (ChunkType chunk_type) {
            Object (
                chunk_type: chunk_type
            );
            build ();
        }

        public DocumentChunk.from_json_object (Json.Object? obj) {
            if (obj != null) {
                raw_content = obj.get_string_member ("raw_content");
                notes = obj.get_string_member ("notes");
                title = obj.get_string_member ("title");
                index = obj.get_int_member ("index");
                chunk_type = (Models.ChunkType) obj.get_int_member ("chunk_type");
                build (raw_content);
            }
        }

        public Json.Object to_json_object () {
            var root = new Json.Object ();
            root.set_string_member ("raw_content", buffer.text);
            root.set_string_member ("title", title);
            root.set_string_member ("notes", notes);
            root.set_int_member ("index", index);
            root.set_int_member ("chunk_type", (int64) chunk_type);

            return root;
        }

        protected void build (string content = "") {
            switch (chunk_type) {
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
            if (this.words_counter_timer != 0) {
                GLib.Source.remove (words_counter_timer);
            }

            // Count words every 200 milliseconds to avoid thrashing the CPU
            this.words_counter_timer = Timeout.add (200, () => {
                words_counter_timer = 0;
                words_count = Utils.Strings.count_words (this.buffer.text);
                estimate_reading_time = Utils.Strings.estimate_reading_time (this.words_count);
                analyze ();
                return false;
            });

            change ();
        }
    }
}
