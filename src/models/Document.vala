namespace Manuscript.Models {
    public class Document : Object {

        public signal void saved (string target_path);
        public signal void load ();
        public signal void read_error (GLib.Error error);
        public signal void save_error (Error e);
        public signal void chunk_added (DocumentChunk chunk, bool active);
        public signal void chunk_removed (DocumentChunk chunk);
        public signal void active_changed (DocumentChunk chunk);
        public signal void drain ();

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
        public string title { get; set; }

        private Gee.ArrayList<DocumentChunk> _chunks;
        public DocumentChunk[] chunks {
            owned get {
                return _chunks.to_array ();
            }
        }

        public DocumentChunk active_chunk { get; private set; }

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
                    return _ ("Untitled");
                } else {
                    return file_path != null ? GLib.Path.get_basename (file_path) : _ ("Untitled");
                }
            }
        }

        protected Document (string ? file_path, bool temporary = false) throws GLib.Error {
            Object (
                temporary: temporary,
                file_path: file_path
            );
            try {
                if (file_path != null) {
                    load_state = DocumentLoadState.LOADING;
                    var res = FileUtils.read (file_path);
                    if (res == null) {
                        warning ("File not read (not found?)");
                        load_state = DocumentLoadState.ERROR;
                        read_error (null);
                    } else {
                        debug ("File read, creating document");
                        build_document (res);
                        load ();
                    }
                }
            } catch (GLib.Error error) {
                warning ("Cannot create document: %s\n", error.message);
                throw error;
            }
        }

        ~Document () {
            debug ("Unloading document");
            unload ();
        }

        protected void build_document (string content) throws GLib.Error {
            // Gtk.SourceLanguageManager manager = Gtk.SourceLanguageManager.get_default ();
            //  buffer = new Gtk.SourceBuffer (new DocumentTagTable () );
            //  buffer.highlight_matching_brackets = false;
            //  buffer.max_undo_levels = -1;
            //  buffer.highlight_syntax = false;
            //  // buffer.language = manager.guess_language (this.file_path, null);
            //  buffer.begin_not_undoable_action ();
            //  buffer.set_text (content, content.length);
            //  buffer.end_not_undoable_action ();

            //  words_count = Utils.Strings.count_words (buffer.text);
            //  estimate_reading_time = Utils.Strings.estimate_reading_time (words_count);

            //  buffer.changed.connect (on_content_changed);
            //  buffer.undo.connect (on_buffer_undo);
            //  buffer.redo.connect (on_buffer_redo);

            //  buffer.insert_text.connect (text_inserted);
            //  buffer.delete_range.connect (range_deleted);

            //  buffer.undo_manager.can_undo_changed.connect (on_can_undo_changed);
            //  buffer.undo_manager.can_redo_changed.connect (on_can_redo_changed);

            try {
                Json.Parser parser = new Json.Parser ();
                parser.load_from_data (content);
                Json.Node node = parser.get_root ();

                Document obj = Json.gobject_deserialize (typeof (Document), node) as Document;
                if (obj == null) {
                    assert (obj != null);
                    // TODO: gracefully manage the case of a "bad" file
                } else {
                    load_state = DocumentLoadState.LOADED;
                }
            } catch (GLib.Error error) {
                throw error;
            }
        }

        /**
         * Adds a chunk to the collection, making it active by default
         */
        public void add_chunk (DocumentChunk chunk, bool activate = true) {
            _chunks.add (chunk);
            chunk_added (chunk, activate);
        }

        public void remove_chunk (DocumentChunk chunk) {
            _chunks.remove (chunk);
            chunk_removed (chunk);
            if (_chunks.size == 0) {
                drain ();
            }
        }

        public void set_active (DocumentChunk chunk) {
            if (chunk != active_chunk && _chunks.contains (chunk) ) {
                active_chunk = chunk;
                active_changed (active_chunk);
            }
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
                //  buffer.changed.disconnect (on_content_changed);
                //  buffer.undo.disconnect (on_buffer_undo);
                //  buffer.redo.disconnect (on_buffer_redo);

                //  buffer.insert_text.disconnect (text_inserted);
                //  buffer.delete_range.disconnect (range_deleted);

                //  buffer.undo_manager.can_undo_changed.disconnect (on_can_undo_changed);
                //  buffer.undo_manager.can_redo_changed.disconnect (on_can_redo_changed);
                buffer.dispose ();
            } else {
                warning ("Document already disposed");
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
