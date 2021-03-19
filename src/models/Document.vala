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

    public interface DocumentBase : Object {
        public abstract string version { get; set; }
        public abstract string uuid { get; set; }
        public abstract string title { get; set; }
        public abstract string background { get; set; }
        public abstract DocumentSettings settings { get; set; }
        public abstract Gee.ArrayList<DocumentChunk> chunks { get; set; }
    }

    public class ChunkParser : Object, Services.ThreadWorker<DocumentChunk> {
        public Json.Node serialized_chunk { get; construct; }
        public Document parent { get; construct; }

        public ChunkParser (Json.Node serialized_chunk, Document parent) {
            Object (
                serialized_chunk: serialized_chunk,
                parent: parent
            );
        }

        public string get_group () {
            return "chunk_parsers";
        }

        public DocumentChunk parse () {
            return DocumentChunk.from_json_object (serialized_chunk.get_object (), parent);
        }

        public DocumentChunk worker_run () {
            return parse ();
        }
    }

    public class DocumentData : Object, DocumentBase {
        public signal void load ();
        public File? file_ref { get; protected set; }
        public string version { get; set; }
        public string uuid { get; set; }
        public string title { get; set; }
        public string background { get; set; }
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

        public string to_json () {
            var gen = new Json.Generator ();
            var root = new Json.Node (Json.NodeType.OBJECT);
            var object = new Json.Object ();
            root.set_object (object);
            gen.set_root (root);

            object.set_string_member ("version", version);
            object.set_string_member ("uuid", uuid);
            object.set_string_member ("title", title);
            object.set_string_member ("background", background);
            object.set_object_member ("settings", settings.to_json_object ());

            // Serialize chunks

            Json.Array chunks_array = new Json.Array.sized (chunks.size);
            var it = chunks.iterator ();
            while (it.next ()) {
                chunks_array.add_object_element (it.@get ().to_json_object ());
            }
            object.set_array_member ("chunks", chunks_array);
            debug (@"Document.to_json -> Serializing $(chunks_array.get_length()) chunks");

            return gen.to_data (null);
        }

        //  public virtual signal void add_chunk (owned DocumentChunk chunk) {}
        //  public virtual signal void remove_chunk (DocumentChunk chunk) {}
        //  public virtual signal bool move_chunk (DocumentChunk chunk, DocumentChunk ? before_this) { return false; }

    }

    public class Document : DocumentData, DocumentBase {
        public signal void saved (string target_path);
        public signal void read_error (GLib.Error error);
        public signal void save_error (GLib.Error e);
        public signal void chunk_added (DocumentChunk chunk, bool active);
        public signal void chunk_removed (DocumentChunk chunk);
        public signal void chunk_moved (DocumentChunk chunk);
        //  public signal void active_changed (DocumentChunk chunk);
        public signal void drain ();

        private string original_path;
        private string modified_path;
        private uint _load_state = DocumentLoadState.EMPTY;

        public DocumentChunk active_chunk { get; private set; }

        public bool temporary { get; set; }

        public bool has_changes {
            get {
                bool changes_found = false;
                var it = chunks.iterator ();
                while (it.next () && !changes_found) {
                    if (it.@get ().has_changes) {
                        changes_found = true;
                        break;
                    }
                }
                return changes_found;
            }
        }

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
            return Path.get_dirname (file_path) == Path.build_path (
                Path.DIR_SEPARATOR_S, Environment.get_user_cache_dir (), Constants.APP_ID
            );
        }

        public async Document.from_file (string path, bool temporary = false) throws DocumentError {
            this (path, temporary);
            //  load_from_file.begin (path, (obj, res) => {
            //      try {
            //          load_from_file.end (res);
            //      } catch (Models.DocumentError document_error) {
            //          critical ("Cannot create document: %s\n", document_error.message);
            //          // throw document_error;
            //      }
            //  });
            yield load_from_file (path);
        }

        public Document.empty () throws GLib.Error {
            this (null, true);
        }

        protected Document (string ? file_path, bool temporary_doc = false) throws DocumentError {
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

        public async void from_json (string data) throws DocumentError {
            var parser = new Json.Parser ();
            SourceFunc callback = from_json.callback;
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

            if (root_object.has_member ("background")) {
                background = root_object.get_string_member ("background");
            } else {
                background = "";
            }

            // Settings parsing
            var settings_object = root_object.get_object_member ("settings");
            settings = new DocumentSettings.from_json_object (settings_object);

            // Chunks parsing
            var chunks_array = root_object.get_array_member ("chunks");
            chunks = new Gee.ArrayList<DocumentChunk> ();

            if (!Services.ThreadPool.supported) {
                foreach (var el in chunks_array.get_elements ()) {
                    add_chunk (DocumentChunk.from_json_object (el.get_object (), (Document) this));
                    // Sort chunks by their index
                    chunks.sort ((a, b) => {
                        return (int) (a.index - b.index);
                    });
                }
            } else {
                uint expected_chunks_length = chunks_array.get_elements ().length ();
                Gee.ArrayList<DocumentChunk> worked_items = new Gee.ArrayList<DocumentChunk> ();

                foreach (var el in chunks_array.get_elements ()) {
                    var worker = new ChunkParser (el, (Document) this);
                    worker.done.connect ((c) => {
                        worked_items.add (c);
                    });

                    Services.ThreadPool.get_default ().add (worker);
                }

                GLib.Idle.add (() => {
                    if (expected_chunks_length == worked_items.size) {
                        debug ("Document parsed, sorting chunks and removing idle task");

                        worked_items.iterator().@foreach ((c) => {
                            add_chunk (c);
                            return GLib.Source.CONTINUE;
                        });

                        chunks.sort ((a, b) => {
                            return (int) (a.index - b.index);
                        });

                        Idle.add ((owned) callback);
                        return GLib.Source.REMOVE;
                    } else {
                        return GLib.Source.CONTINUE;
                    }
                });

                yield;
            }
        }

        private async void load_from_file (string file_path) throws DocumentError {
            load_state = DocumentLoadState.LOADING;
            File file_for_path = File.new_for_path (file_path);

            string? res = null;
            try {
                res = yield FileUtils.read_async (file_for_path);
            } catch (Error e) {
                throw new DocumentError.READ(e.message);
            }

            if (res == null) {
                warning ("File not read (not found?)");
                load_state = DocumentLoadState.ERROR;
                throw new DocumentError.NOT_FOUND ("File not found");
            } else {
                file_ref = file_for_path;
                yield from_json (res);
                load ();
            }
        }

        /**
         * Adds a chunk to the collection, making it active by default
         */
        public signal void add_chunk (owned DocumentChunk chunk) {
            chunks.add (chunk);
            debug (@"Chunk '$(chunk.title)' added to document");
        }

        public signal void remove_chunk (DocumentChunk chunk) {
            chunks.remove (chunk);
            chunk_removed (chunk);
            if (chunks.size == 0) {
                drain ();
            }

            debug ("Chunk removed from document");
        }

        /**
         * Moves `chunk` to the position prior to `before_this`.
         */
        public signal bool move_chunk (DocumentChunk chunk, DocumentChunk ? before_this) {
            if (before_this == null) {
                // `chunk` moved to the bottom
                debug ("Moving item to the bottom");
                chunk.index = chunks_by_type_size (chunk.kind) - 1;
            } else {
                chunk.index = before_this.index - 1;

                int idx = 0;
                iter_chunks_by_type (chunk.kind)
                    .order_by ((a, b) => {
                        if (a.index < b.index) {
                            return -1;
                        } else if (a.index > b.index) {
                            return 1;
                        } else {
                            return 0;
                        }
                    })
                    .@foreach ((c) => {
                        if (c.index != idx) {
                            c.index = idx;
                        }
                        idx ++;
                        return true;
                    });
            }

            chunk_moved (chunk);
            return true;
        }

        //  public void set_active (DocumentChunk chunk) {
        //      if (chunk != active_chunk && chunks.contains (chunk) ) {
        //          active_chunk = chunk;
        //          active_changed (active_chunk);
        //      }
        //  }

        public long save (string ? path = null) {
            try {
                if (path != null) {
                    modified_path = path;
                }
                string data = to_json ();
                long written_bytes = FileUtils.save (data, file_path);
                info (@"Document saved to $file_path ($written_bytes bytes written)");
                this.temporary = false;
                this.saved (file_path);
                return written_bytes;
            } catch (Error e) {
                critical (e.message);
                this.save_error (e);
                return 0;
            }
        }

        public async Thread<long> save_async (string ? path = null) {
            return new GLib.Thread<long> ("save_thread", () => {
                return this.save (path);
            });
        }

        public Gee.Iterator<DocumentChunk> iter_chunks_with_changes () {
            return chunks.filter ((item) => {
                return item.has_changes;
            });
        }

        public Gee.Iterator<DocumentChunk> iter_chunks_by_type (ChunkType kind) {
            return chunks.filter ((item) => {
                return item.kind == kind;
            });
        }

        public int chunks_by_type_size (ChunkType kind) {
            int i = 0;
            chunks.filter ((item) => {
                return item.kind == kind;
            }).@foreach (() => {
                i++;
                return true;
            });

            return i;
        }
    }
}
