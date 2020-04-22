namespace Manuscript {
    public class Document : Object {

        public signal void saved (string target_path);
        public signal void load ();
        public signal void change ();
        public signal void undo_queue_drain ();
        public signal void undo ();
        public signal void redo ();
        public signal void analyze ();
        public signal void read_error ();
        public signal void save_error (Error e);

        protected Gtk.SourceBuffer _buffer;
        protected string _raw_content;
        private string original_path;
        private string modified_path;
        private uint words_counter_timer = 0;
        private uint _load_state = DocumentLoadState.EMPTY;

        public uint words_count { get; private set; }
        public double estimate_reading_time { get; private set; }
        public bool has_changes { get; private set; }
        public bool temporary { get; construct; }

        public string file_path {
            get {
                return modified_path != null ? modified_path : original_path;
            }

            construct {
                original_path = value;
            }
        }

        public uint load_state {
            get {
                return _load_state;
            }

            private set {
                _load_state = value;
            }
        }

        public Gtk.SourceBuffer buffer {
            get {
                return this._buffer;
            }

            set {
                this._buffer = value;
            }
        }

        public bool loaded {
            get {
                return load_state == DocumentLoadState.LOADED;
            }
        }

        public string text {
            owned get {
                return this.buffer != null ? this.buffer.text : null;
            }
        }

        public string filename {
            owned get {
                if (temporary) {
                    return "Untitled.txt";
                } else {
                    return file_path != null ? GLib.Path.get_basename (file_path) : "Untitled.txt";
                }
            }
        }

        protected Document (string? file_path, bool temporary = false) {
            Object (
                temporary: temporary,
                file_path: file_path
            );
        }

        construct {
            if (this.file_path != null) {
                try {
                    load_state = DocumentLoadState.LOADING;
                    FileUtils.read_async.begin (File.new_for_path (this.file_path), (obj, res) => {
                        if (res == null) {
                            warning ("File not read (not found?)");
                            load_state = DocumentLoadState.ERROR;
                            read_error ();
                        } else {
                            debug ("File read, creating document");
                            try {
                                string? content = FileUtils.read_async.end (res);
                                if (content != null) {
                                    this.build_document (content);
                                } else {
                                    this.build_document ("");
                                }
                                this.load ();
                            } catch (GLib.Error err) {
                                warning ("File unreadable");
                                load_state = DocumentLoadState.ERROR;
                                read_error ();
                            }
                        }
                    });
                } catch (Error err) {
                      this.build_document ("");
                }
            }
        }

        ~Document () {
            debug ("Unloading document");
            unload ();
        }

        protected void build_document (string content) {
            // Gtk.SourceLanguageManager manager = Gtk.SourceLanguageManager.get_default ();
            buffer = new Gtk.SourceBuffer (new DocumentTagTable ());
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

            load_state = DocumentLoadState.LOADED;
        }

        public void save (string path = "@") {
            try {
                if (path != "@") {
                    modified_path = path;
                }
                FileUtils.save_buffer (_buffer, file_path);
                this.has_changes = false;
                this.saved (file_path);
            } catch (Error e) {
                this.save_error (e);
            }
        }

        public void unload () {
          if (buffer != null) {
            buffer.changed.disconnect (on_content_changed);
            buffer.undo.disconnect (on_buffer_undo);
            buffer.redo.disconnect (on_buffer_redo);

            buffer.insert_text.disconnect (text_inserted);
            buffer.delete_range.disconnect (range_deleted);

            buffer.undo_manager.can_undo_changed.disconnect (on_can_undo_changed);
            buffer.undo_manager.can_redo_changed.disconnect (on_can_redo_changed);
            buffer.dispose ();
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

        private void text_inserted () {}

        private void range_deleted () {}

        private void on_can_undo_changed () {
          if (buffer.can_undo) {
            has_changes = true;
            this.change ();
          } else {
            has_changes = false;
          }
        }

        private void on_can_redo_changed () {
          this.change ();
        }

        private void on_buffer_redo () {
          this.redo ();
        }

        private void on_buffer_undo () {
          undo ();
          if (!buffer.undo_manager.can_undo ()) {
            undo_queue_drain ();
          }
        }

        public static Document from_file (string path, bool temporary = false) throws GLib.Error {
          return new Document (path, temporary);
        }

        public static Document empty () throws GLib.Error {
          return new Document (null, true);
        }
    }
}
