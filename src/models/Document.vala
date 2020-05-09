namespace Manuscript.Models {
    public errordomain DocumentError {
        READ
    }

    public interface DocumentBase : Object {
        public abstract string uuid { get; set; }
        public abstract string title { get; set; }
        public abstract DocumentSettings settings { get; set; }
        public abstract List<DocumentChunk> chunks { owned get; set; }

        public abstract DocumentBase get_empty ();
    }


    public class DocumentData : Object, DocumentBase, Json.Serializable {
        public string uuid { get; set; }
        public string title { get; set; }
        public DocumentSettings settings { get; set; }

        private Gee.ArrayList<DocumentChunk> _chunks;
        public new List<DocumentChunk> chunks {
            owned get {
                if (_chunks != null) {
                    return Conversion.to_list (_chunks);
                } else {
                    return new List<DocumentChunk> ();
                }
            }
            set {
                _chunks = Conversion.to_array_list (value);
            }
        }

        public void copy_from (DocumentBase source) {
            title = source.title;
            uuid = source.uuid;
            settings = source.settings;
            chunks = source.chunks;
        }

        public DocumentBase get_empty () {
            return new DocumentData ();
        }
    }

    public class Document : DocumentData, DocumentBase, Json.Serializable {
        protected const string[] SERIALIZABLE_PROPERIES = {
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

        private Gee.ArrayList<DocumentChunk> _chunks;
        public new List<DocumentChunk> chunks {
            owned get {
                if (_chunks != null) {
                    return Conversion.to_list (_chunks);
                } else {
                    return new List<DocumentChunk> ();
                }
            }

            set {
                _chunks = Conversion.to_array_list (value);
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

        protected Document (string ? file_path, bool temporary_doc = false) throws GLib.Error {
            Object (
                file_path: file_path,
                uuid: GLib.Uuid.string_random ()
            );
            try {
                temporary = temporary_doc;
                _chunks = new Gee.ArrayList<DocumentChunk> ();
                settings = new DocumentSettings ();
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
        }

        protected void build_document (string content) throws GLib.Error {
            try {
                Json.Parser parser = new Json.Parser ();
                parser.load_from_data (content);
                Json.Node node = parser.get_root ();
                DocumentData obj = Json.gobject_deserialize (typeof (DocumentData), node) as DocumentData;
                if (obj == null) {
                    throw new DocumentError.READ (@"Cannot parse manuscript from content of $file_path");
                } else {
                    copy_from (obj);
                    load_state = DocumentLoadState.LOADED;
                }
            } catch (GLib.Error error) {
                critical (@"Error building document: $(error.message)");
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

        public void save (string ? path = null) {
            try {
                if (path != null) {
                    modified_path = path;
                }
                // FileUtils.save_buffer (_buffer, file_path);
                string data = Json.gobject_to_data (this, null);
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

        //  public DocumentData flatten () {
        //      return this as DocumentData;
        //  }

        // ******
        // Json serializable impl
        // ******

        // public bool deserialize_property (string property_name, out Value value, ParamSpec pspec, Json.Node property_node) {
        // }

        // public new Value get_property (ParamSpec pspec) {}

        /**
         * Only list serializable properties
         */
        public (unowned ParamSpec)[] list_properties () {
            ParamSpec[] specs = new ParamSpec[Document.SERIALIZABLE_PROPERIES.length];
            Type type = typeof (Document);
            ObjectClass ocl = (ObjectClass) type.class_ref ();
            var i = 0;
            foreach (string prop in Document.SERIALIZABLE_PROPERIES) {
                debug (@"Getting prop $prop");
                ParamSpec p = ocl.find_property (prop);
                assert (p != null);
                specs[i] = p;
                i++;
            }
            
            return specs;
        }

        public Json.Node serialize_property (string property_name, Value value, ParamSpec pspec) {
            var node = new Json.Node.alloc ();
            Type prop_type = value.type ();
            debug (@"$property_name/$prop_type");
            switch (prop_type) {
                case Type.STRING:
                    var v = value.get_string ();
                    if (v == null) {
                        node.init_null ();
                    } else {
                        node.init_string (v);
                    }
                    break;
                case Type.OBJECT:
                    var v = value.get_object ();
                    if (v == null) {
                        node.init_null ();
                    } else {
                        node = Json.gobject_serialize ();
                    }
                    break;
                default:
                    switch (property_name) {
                        case "settings":
                            debug ("Serializing settings");
                            node = Json.gobject_serialize (value.get_object ());
                            break;
                        case "chunks":
                            debug ("Serializing chunks");
                            var json_array = new Json.Array.sized (chunks.length ());
                            var it = _chunks.iterator ();
                            while (it.has_next ()) {
                                it.next ();
                                json_array.add_element (Json.gobject_serialize (it.@get ()));
                            }
                            node.init_array (json_array);
                            break;
                        default:
                            node.init_null ();
                            break;
                    }
                    break;
            }

            return node;
        }


        //  public virtual void set_property (ParamSpec pspec, Value value) {}
    }
}
