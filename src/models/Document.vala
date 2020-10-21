/*
 * Copyright 2020 Andrea Coronese <sixpounder@protonmail.com>
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
    public errordomain DocumentError {
        NOT_FOUND,
        READ,
        PARSE
    }

    public class IndexedItem<G> : Object {
        public G data { get; set; }
        public int index { get; set; }

        public IndexedItem (G data, int index) {
            Object (
                data: data,
                index: index
            );
        }
    }

    public interface DocumentBase : Object {
        public abstract string version { get; set; }
        public abstract string uuid { get; set; }
        public abstract string title { get; set; }
        public abstract string synopsis { get; set; }
        public abstract DocumentSettings settings { get; set; }
        public abstract Gee.ArrayList<DocumentChunk> chunks { get; set; }
    }


    public class DocumentData : Object, DocumentBase {
        public string version { get; set; }
        public string uuid { get; set; }
        public string title { get; set; }
        public string synopsis { get; set; }
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

        public void from_json (string data) throws DocumentError {
            var parser = new Json.Parser ();
            try {
                parser.load_from_data (data, -1);
            } catch (Error error) {
                throw new DocumentError.PARSE (@"Cannot parse manuscript file: $(error.message)");
            }

            var root_object = parser.get_root ().get_object ();

            if (root_object.has_member ("version")) {
                version = root_object.get_string_member ("version");
            } else {
                version = "1.0";
            }

            if (root_object.has_member ("uuid")) {
                uuid = root_object.get_string_member ("uuid");
            } else {
                info ("Document has no uuid, generating one now");
                uuid = GLib.Uuid.string_random ();
            }

            title = root_object.get_string_member ("title");

            if (root_object.has_member ("synopsis")) {
                synopsis = root_object.get_string_member ("synopsis");
            } else {
                synopsis = "";
            }

            // Settings parsing
            var settings_object = root_object.get_object_member ("settings");
            settings = new DocumentSettings.from_json_object (settings_object);

            // Chunks parsing
            var chunks_array = root_object.get_array_member ("chunks");
            chunks = new Gee.ArrayList<DocumentChunk> ();
            foreach (var el in chunks_array.get_elements ()) {
                add_chunk (new DocumentChunk.from_json_object (el.get_object ()), false);
            }

            // Sort chunks by their index
            chunks.sort ((a, b) => {
                return (int) (a.index - b.index);
            });
        }

        public string to_json () {
            var gen = new Json.Generator();
            var root = new Json.Node(Json.NodeType.OBJECT);
            var object = new Json.Object();
            root.set_object(object);
            gen.set_root(root);

            object.set_string_member ("version", version);
            object.set_string_member ("uuid", uuid);
            object.set_string_member ("title", title);
            object.set_string_member ("synopsis", synopsis);
            object.set_object_member ("settings", settings.to_json_object ());
            
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
        public virtual void remove_chunk (DocumentChunk chunk) {}
        public virtual bool move_chunk (DocumentChunk chunk, int index) { return false; }

    }

    public class Document : DocumentData, DocumentBase {
        public const string[] SERIALIZABLE_PROPERIES = {
            "version",
            "uuid",
            "title",
            "chunks",
            "settings"
        };

        public signal void saved (string target_path);
        public signal void load ();
        public signal void read_error (GLib.Error error);
        public signal void save_error (GLib.Error e);
        public signal void chunk_added (DocumentChunk chunk, bool active);
        public signal void chunk_removed (DocumentChunk chunk);
        public signal void chunk_moved (DocumentChunk chunk);
        public signal void active_changed (DocumentChunk chunk);
        public signal void drain ();

        private string original_path;
        private string modified_path;
        private uint _load_state = DocumentLoadState.EMPTY;

        public uint words_count { get; private set; }
        public double estimate_reading_time { get; private set; }

        public bool has_changes {
            get {
                bool changes_found = false;
                var it = chunks.iterator ();
                while (it.next () && !changes_found) {
                    if (it.@get ().has_changes) {
                        changes_found = true;
                    }
                }
                return changes_found;
            }
        }

        public bool temporary { get; set; }

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

        // A file is considered to be temporary if it is located into the user's cache folder
        public bool is_temporary () {
            return Path.get_dirname (file_path) == Path.build_path(Path.DIR_SEPARATOR_S, Environment.get_user_cache_dir (), Constants.APP_ID);
        }

        public Document.from_file (string path, bool temporary = false) throws GLib.Error {
            this (path, temporary);
            try {
                this.load_from_file (path);
            } catch (Models.DocumentError document_error) {
                critical ("Cannot create document: %s\n", document_error.message);
                throw document_error;
            }
        }

        public Document.empty () throws GLib.Error {
            this (null, true);
        }

        protected Document (string ? file_path, bool temporary_doc = false) throws GLib.Error, DocumentError {
            Object (
                file_path: file_path,
                uuid: GLib.Uuid.string_random (),
                version: "1.0",
                temporary: temporary_doc
            );
        }

        construct {
            chunks = new Gee.ArrayList<DocumentChunk> ();
            settings = new DocumentSettings ();
        }

        ~Document () {
            debug (@"Unloading document $uuid");
        }

        private void load_from_file (string file_path) throws DocumentError {
            load_state = DocumentLoadState.LOADING;
            var res = FileUtils.read (file_path);
            if (res == null) {
                warning ("File not read (not found?)");
                load_state = DocumentLoadState.ERROR;
                throw new DocumentError.NOT_FOUND ("File not found");
            } else {
                from_json (res);

                debug (chunks.size.to_string ());
            }
        }

        protected Gee.Iterator<IndexedItem<DocumentChunk>> get_chunks_group (ChunkType chunk_type) {
            int i = 0;
            Gee.Iterator<IndexedItem<DocumentChunk>> filtered_iter = chunks.filter ((item) => {
                return item.chunk_type == chunk_type;
            }).map<IndexedItem<DocumentChunk>> ((item) => {
                var c_item = new IndexedItem<DocumentChunk> (item, i);
                i += 1;
                return c_item;
            });

            return filtered_iter;
        }

        /**
         * Adds a chunk to the collection, making it active by default
         */
        public override void add_chunk (DocumentChunk chunk, bool activate = true) {
            chunks.add (chunk);
            chunk_added (chunk, activate);
        }

        public override void remove_chunk (DocumentChunk chunk) {
            chunks.remove (chunk);
            chunk_removed (chunk);
            if (chunks.size == 0) {
                drain ();
            }
        }

        /**
         * Moves `chunk` to `index`, where `index` is supposed to be an index representing
         * a flattened value for chunks of the same type
         */
        public override bool move_chunk (DocumentChunk chunk, int index) {
            bool r = true;
            Gee.Iterator<IndexedItem<DocumentChunk>> filtered_iter = get_chunks_group (chunk.chunk_type);

            filtered_iter.@foreach((indexed_item) => {
                chunks.filter ((item) => {
                    return item.chunk_type == chunk.chunk_type;
                }).@foreach((item) => {
                    if (item == indexed_item.data) {
                        //  var real_index = chunks.index_of (indexed_item.data);
                        //  debug (@"Index in local collection for $(chunk.title): $real_index - Wanted index: $index");
                        //  chunk.index = index;
                        item.index = indexed_item.index;
                        r = true;
                        return false;
                    } else {
                        return true;
                    }
                });

                return true;
            });

            chunk_moved (chunk);

            return r;
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
                debug (@"Document saved to $file_path ($written_bytes bytes written)");
                this.temporary = false;
                this.saved (file_path);
            } catch (Error e) {
                this.save_error (e);
            }
        }

        public DocumentChunk[] chunks_with_changes () {
            Gee.ArrayList<DocumentChunk> changed = new Gee.ArrayList<DocumentChunk> ();
            var it = chunks.iterator ();
            it.filter((item) => {
                return item.has_changes;
            }).@foreach((item) => {
                changed.add(item);
                return true;
            });

            return changed.to_array ();
        }
    }
}
