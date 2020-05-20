namespace Manuscript.Models {
    public errordomain DocumentError {
        NOT_FOUND,
        READ,
        PARSE
    }

    public interface DocumentBase : Object {
        public abstract string version { get; set; }
        public abstract string uuid { get; set; }
        public abstract string title { get; set; }
        public abstract DocumentSettings settings { get; set; }
        public abstract Gee.ArrayList<DocumentChunk> chunks { get; set; }
    }


    public class DocumentData : Object, DocumentBase {
        public string version { get; set; }
        public string uuid { get; set; }
        public string title { get; set; }
        public DocumentSettings settings { get; set; }
        
        private Gee.ArrayList<DocumentChunk> _chunks;
        public new Gee.ArrayList<DocumentChunk> chunks {
            get {
                return _chunks;
            }
            set {
                _chunks = value;
            }
        }

        public DocumentData.from_json (string data) throws DocumentError {
            var parser = new Json.Parser ();
            try {
                parser.load_from_data (data, -1);
            } catch (Error error) {
                throw new DocumentError.PARSE (@"Cannot parse manuscript file: $(error.message)");
            }

            var root_object = parser.get_root ().get_object ();

            uuid = root_object.get_string_member ("uuid");
            title = root_object.get_string_member ("title");

            // Settings parsing
            var settings_object = root_object.get_object_member ("settings");
            settings = new DocumentSettings.from_json_object (settings_object);

            // Chunks parsing
            var chunks_array = root_object.get_array_member ("chunks");
            chunks = new Gee.ArrayList<DocumentChunk> ();
            foreach (var el in chunks_array.get_elements ()) {
                add_chunk (new DocumentChunk.from_json_object (el.get_object ()), false);
            }
        }

        public string to_json () {
            var gen = new Json.Generator();
            var root = new Json.Node(Json.NodeType.OBJECT);
            var object = new Json.Object();
            root.set_object(object);
            gen.set_root(root);

            object.set_string_member("version", version);
            object.set_string_member("uuid", uuid);
            object.set_string_member("title", title);
            object.set_object_member("settings", settings.to_json_object ());
            
            // Serialize chunks

            Json.Array chunks_array = new Json.Array.sized (chunks.size);
            var it = chunks.iterator ();
            while (it.next ()) {
                chunks_array.add_object_element (it.@get ().to_json_object ());
            }
            object.set_array_member ("chunks", chunks_array);

            return gen.to_data (null);
        }

        public virtual void add_chunk (DocumentChunk chunk, bool activate = true) {}
        public virtual void remove_chunk (DocumentChunk chunk, bool activate = true) {}

    }

    public class Document : DocumentData, DocumentBase {
        public const string[] SERIALIZABLE_PROPERIES = {
            "version",
            "uuid",
            "title",
            "chunks",
            "settings"
        };

        public Document.from_file (string path, bool temporary = false) throws GLib.Error {
            this (path, temporary);
        }

        public Document.empty () throws GLib.Error {
            this (null, true);
        }

        public signal void saved (string target_path);
        public signal void load ();
        public signal void read_error (GLib.Error error);
        public signal void save_error (Error e);
        public signal void chunk_added (DocumentChunk chunk, bool active);
        public signal void chunk_removed (DocumentChunk chunk);
        public signal void active_changed (DocumentChunk chunk);
        public signal void drain ();

        private string original_path;
        private string modified_path;
        private uint _load_state = DocumentLoadState.EMPTY;

        public uint words_count { get; private set; }
        public double estimate_reading_time { get; private set; }
        public bool has_changes { get; private set; }
        public bool temporary { get; private set; }

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

        public bool loaded {
            get {
                return load_state == DocumentLoadState.LOADED;
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

        protected Document (string ? file_path, bool temporary_doc = false) throws GLib.Error, DocumentError {
            Object (
                file_path: file_path,
                uuid: GLib.Uuid.string_random (),
                version: "1.0",
                temporary: true
            );
            try {
                temporary = temporary_doc;
                chunks = new Gee.ArrayList<DocumentChunk> ();
                settings = new DocumentSettings ();
                if (file_path != null) {
                    load_state = DocumentLoadState.LOADING;
                    var res = FileUtils.read (file_path);
                    if (res == null) {
                        warning ("File not read (not found?)");
                        load_state = DocumentLoadState.ERROR;
                        throw new DocumentError.NOT_FOUND ("File not found");
                    } else {
                        debug ("File read");
                        var parser = new Json.Parser ();
                        try {
                            parser.load_from_data (res, -1);
                        } catch (Error error) {
                            throw new DocumentError.PARSE (@"Cannot parse manuscript file: $(error.message)");
                        }

                        var root_object = parser.get_root ().get_object ();

                        version = root_object.get_string_member ("version");
                        uuid = root_object.get_string_member ("uuid");
                        title = root_object.get_string_member ("title");

                        // Settings parsing
                        var settings_object = root_object.get_object_member ("settings");
                        settings = new DocumentSettings.from_json_object (settings_object);

                        // Chunks parsing
                        var chunks_array = root_object.get_array_member ("chunks");
                        chunks = new Gee.ArrayList<DocumentChunk> ();
                        foreach (var el in chunks_array.get_elements ()) {
                            add_chunk (new DocumentChunk.from_json_object (el.get_object ()), false);
                        }
                    }
                }
            } catch (GLib.Error error) {
                critical ("Cannot create document: %s\n", error.message);
                throw error;
            }
        }

        ~Document () {
            debug (@"Unloading document $uuid");
        }

        protected void build_document (string content) throws GLib.Error {
            try {
                DocumentData obj = new DocumentData.from_json (content);
                if (obj == null) {
                    throw new DocumentError.READ (@"Cannot parse manuscript from content of $file_path");
                } else {
                    load_state = DocumentLoadState.LOADED;
                }
            } catch (Error err) {
                throw new DocumentError.READ (@"Cannot parse manuscript from content of $file_path");
            }
        }

        /**
         * Adds a chunk to the collection, making it active by default
         */
        public new void add_chunk (DocumentChunk chunk, bool activate = true) {
            chunks.add (chunk);
            chunk_added (chunk, activate);
        }

        public new void remove_chunk (DocumentChunk chunk) {
            chunks.remove (chunk);
            chunk_removed (chunk);
            if (chunks.size == 0) {
                drain ();
            }
        }

        public void set_active (DocumentChunk chunk) {
            if (chunk != active_chunk && chunks.contains (chunk) ) {
                active_chunk = chunk;
                active_changed (active_chunk);
            }
        }

        public void save (string ? path = null) {
            try {
                if (path != null) {
                    modified_path = path;
                }
                string data = to_json ();
                long written_bytes = FileUtils.save (data, file_path);
                debug (@"Written $written_bytes bytes");
                debug (data);
                this.has_changes = false;
                this.temporary = false;
                this.saved (file_path);
            } catch (Error e) {
                this.save_error (e);
            }
        }
    }
}
