namespace Manuscript.Models {
    public errordomain DocumentError {
        READ
    }

    public interface DocumentBase : Object {
        public abstract string title { get; set; }
        public abstract void copy_from (DocumentBase base_data);
    }

    public class DocumentData : Object, DocumentBase {
        public string title { get; set; }
        public void copy_from (DocumentBase base_data) {
            title = base_data.title;
        }
    }

    public class Document : DocumentData {

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
        public string uuid { get; construct; }

        private Gee.ArrayList<DocumentChunk> _chunks;

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
                file_path: file_path,
                uuid: GLib.Uuid.string_random ()
            );
            try {
                _chunks = new Gee.ArrayList<DocumentChunk> ();
                if (file_path != null) {
                    load_state = DocumentLoadState.LOADING;
                    var res = FileUtils.read (file_path);
                    if (res == null) {
                        warning ("File not read (not found?)");
                        load_state = DocumentLoadState.ERROR;
                    } else {
                        debug ("File read");
                        build_document (res);
                    }
                }
            } catch (GLib.Error error) {
                critical ("Cannot create document: %s\n", error.message);
                throw error;
            }
        }

        ~Document () {
            debug (@"Unloading document $uuid");
            unload ();
        }

        protected void build_document (string content) throws GLib.Error {
            try {
                Json.Parser parser = new Json.Parser ();
                parser.load_from_data (content);
                Json.Node node = parser.get_root ();

                DocumentBase obj = Json.gobject_deserialize (typeof (DocumentData), node) as DocumentData;
                if (obj == null) {
                    throw new DocumentError.READ (@"Cannot parse manuscript from content of $file_path");
                } else {
                    copy_from (obj);
                    load_state = DocumentLoadState.LOADED;
                }
            } catch (GLib.Error error) {
                throw error;
            }
        }

        public DocumentChunk[] get_chunks () {
            return _chunks.to_array ();
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
                buffer.dispose ();
            } else {
                warning ("Document buffer already disposed");
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
