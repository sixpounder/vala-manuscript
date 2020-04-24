namespace Manuscript.Models {
    public class DocumentChunk : Object, Json.Serializable {

        public signal void change ();
        public signal void undo_queue_drain ();
        public signal void undo ();
        public signal void redo ();
        public signal void analyze ();

        protected Gtk.SourceBuffer _buffer;
        protected uint words_counter_timer = 0;
        public virtual ChunkType chunk_type { get; construct; }
        public bool has_changes { get; private set; }
        public uint words_count { get; private set; }
        public double estimate_reading_time { get; private set; }
        public string notes { get; set; }
        public string title { get; set; }
        public string raw_content { get; set; }
        public uint index { get; set; }

        public Gtk.SourceBuffer buffer {
            get {
                return _buffer;
            }

            private set {
                _buffer = value;
            }
        }

        public DocumentChunk.empty () {
            build ();
        }

        public DocumentChunk.from_data (string data) {

        }

        public static DocumentChunk from_node (Json.Node node) {
            var chunk = Json.gobject_deserialize (typeof (DocumentChunk), node) as DocumentChunk;
            chunk.build (chunk.raw_content);

            return chunk;
        }

        protected void build (string ? content = "") {
            buffer = new Gtk.SourceBuffer (new DocumentTagTable () );
            buffer.highlight_matching_brackets = false;
            buffer.max_undo_levels = -1;
            buffer.highlight_syntax = false;
            // buffer.language = manager.guess_language (this.file_path, null);
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
