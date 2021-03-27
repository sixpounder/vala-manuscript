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

    public class ArchivableItem : Object {
        public uint8[] data;
        public string name { get; set construct; }
        public string group { get; set construct; }

        public ArchivableItem () {}

        public ArchivableItem.with_props (string name, string group, uint8[] data) {
            Object (
                name: name,
                group: group
            );

            this.data = data;
        }
    }

    public interface Archivable : Object {
        public abstract Gee.Collection<ArchivableItem> to_archivable_entries ();
        public abstract Archivable from_archive_entries (Gee.Collection<ArchivableItem> entries);
    }

    public interface DocumentBase : Object {
        public abstract string version { get; set; }
        public abstract string uuid { get; set; }
        public abstract string title { get; set; }
        public abstract DocumentSettings settings { get; set; }
        public abstract Gee.ArrayList<DocumentChunk> chunks { get; set; }
    }

    public class ChunkParser : Object, Services.ThreadWorker<DocumentChunk> {
        public Json.Node serialized_chunk { get; construct; }
        public weak Document parent { get; construct; }

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
            assert (parent != null);
            return chunk_from_json_object (serialized_chunk.get_object (), parent);
        }

        public DocumentChunk worker_run () {
            return parse ();
        }
    }

    public class DocumentData : Object, DocumentBase, Archivable {
        public signal void load ();
        public File? file_ref { get; protected set; }
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

        public string to_json () {
            var gen = new Json.Generator ();
            var root = new Json.Node (Json.NodeType.OBJECT);
            var object = new Json.Object ();
            root.set_object (object);
            gen.set_root (root);

            object.set_string_member ("version", version);
            object.set_string_member ("uuid", uuid);
            object.set_string_member ("title", title);
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

        public Gee.Collection<ArchivableItem> to_archivable_entries () {
            var gen = new Json.Generator ();
            var root = new Json.Node (Json.NodeType.OBJECT);
            var object = new Json.Object ();
            root.set_object (object);
            gen.set_root (root);
            object.set_string_member ("version", version);
            object.set_string_member ("uuid", uuid);
            object.set_string_member ("title", title);

            var c = new Gee.ArrayList<ArchivableItem> ();
            var item = new ArchivableItem ();
            item.name = "manifest.json";
            item.group = "";
            item.data = gen.to_data (null).data;

            c.add (item);

            return c;
        }

        public Archivable from_archive_entries (Gee.Collection<ArchivableItem> entries) {
            return this;
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

            set construct {
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
            yield load_from_archive_file (path);
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

        public void from_json (uint8[] data) throws DocumentError {
            var parser = new Json.Parser ();
            //  SourceFunc callback = from_json.callback;
            try {
                parser.load_from_stream (new MemoryInputStream.from_data (data, null), null);
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

            // Settings parsing
            //  var settings_object = root_object.get_object_member ("settings");
            //  settings = new DocumentSettings.from_json_object (settings_object);

            // Chunks parsing
            //  var chunks_array = root_object.get_array_member ("chunks");
            //  chunks = new Gee.ArrayList<DocumentChunk> ();

            //  if (!Services.ThreadPool.supported) {
            //      foreach (var el in chunks_array.get_elements ()) {
            //          add_chunk (chunk_from_json_object (el.get_object (), (Document) this));
            //          // Sort chunks by their index
            //          chunks.sort ((a, b) => {
            //              return (int) (a.index - b.index);
            //          });
            //      }
            //  } else {
            //      Mutex worked_items_mutex = Mutex ();
            //      uint expected_chunks_length = chunks_array.get_elements ().length ();
            //      Gee.ArrayList<DocumentChunk> worked_items = new Gee.ArrayList<DocumentChunk> ();

            //      foreach (var el in chunks_array.get_elements ()) {
            //          var worker = new ChunkParser (el, (Document) this);
            //          worker.done.connect ((c) => {
            //              worked_items_mutex.@lock ();
            //              worked_items.add (c);
            //              if (expected_chunks_length == worked_items.size) {
            //                  debug ("Document parsed, sorting chunks and removing idle task");
            //                  worked_items.iterator ().@foreach ((c) => {
            //                      add_chunk (c);
            //                      return GLib.Source.CONTINUE;
            //                  });

            //                  chunks.sort ((a, b) => {
            //                      return (int) (a.index - b.index);
            //                  });

            //                  Idle.add ((owned) callback);
            //              }
            //              worked_items_mutex.@unlock ();
            //          });

            //          Services.ThreadPool.get_default ().add (worker);
            //      }

            //      yield;
            //  }
        }

        public long save (string ? path = null) {
            //  try {
            //      if (path != null) {
            //          modified_path = path;
            //      }
            //      string data = to_json ();
            //      long written_bytes = FileUtils.save (data, file_path);
            //      info (@"Document saved to $file_path ($written_bytes bytes written)");
            //      this.temporary = false;
            //      // Dev: save both formats
            //      save_archive (@"$file_path.$(Constants.DEFAULT_ARCHIVE_FILE_EXT)");
            //      this.saved (file_path);

            //      return written_bytes;
            //  } catch (Error e) {
            //      critical (e.message);
            //      this.save_error (e);
            //      return 0;
            //  }
            return save_archive (path);
        }

        public long save_archive (string ? path = null) {
            if (path != null) {
                modified_path = path;
            }

            ssize_t size = 0;
            Archive.Write archive = new Archive.Write ();
            archive.add_filter_gzip ();
            archive.set_format_pax_restricted ();
            archive.open_filename (file_path);

            Gee.ArrayList<ArchivableItem> archive_items = new Gee.ArrayList<ArchivableItem> ();
            archive_items.add_all (to_archivable_entries ());
            archive_items.add_all (settings.to_archivable_entries ());
            var it = chunks.iterator ();
            while (it.next ()) {
                var item = it.@get ();
                archive_items.add_all (item.to_archivable_entries ());
            }

            foreach (ArchivableItem item in archive_items) {
                Archive.Entry entry = new Archive.Entry ();
                entry.set_pathname (
                    item.group != "" ? GLib.Path.build_filename (item.group, item.name) : item.name
                );
                entry.set_size (item.data.length);
                entry.set_filetype (Archive.FileType.IFREG);
                entry.set_perm (0644);
                if (archive.write_header (entry) != Archive.Result.OK) {
                    critical ("Error writing '%s': %s (%d)", item.name, archive.error_string (), archive.errno ());
                    continue;
                }
                debug (@"Writing $(item.name): $(entry.pathname ()) - $(item.data.length)");
                size += archive.write_data (item.data);
            }

            if (archive.close () != Archive.Result.OK) {
                critical ("Error closing archive: %s", archive.error_string ());
            } else {
                info (@"Document saved to $file_path ($size bytes of data)");
            }

            //  info (@"Document saved to $file_path ($written_bytes bytes written)");
            this.temporary = false;
            //  this.saved (file_path);
            return (long) size;
        }

        public async Thread<long> save_async (string ? path = null) {
            return new GLib.Thread<long> ("save_thread", () => {
                return this.save (path);
            });
        }

        private async void load_from_archive_file (string file_path) throws DocumentError {
            chunks.clear ();

            File file_for_path = File.new_for_path (file_path);

            if (file_for_path.query_exists ()) {
                load_state = DocumentLoadState.LOADING;
                Archive.Read archive = new Archive.Read ();
                archive.support_format_all ();
                archive.support_filter_gzip ();

                if (archive.open_filename (file_for_path.get_path (), 10240) != Archive.Result.OK) {
                    critical (
                        "Error opening %s: %s (%d)",
                        file_for_path.get_path (),
                        archive.error_string (),
                        archive.errno ()
                    );
                    load_state = DocumentLoadState.ERROR;
                    throw new DocumentError.READ (archive.error_string ());
                }

                file_ref = file_for_path;
                yield read_archive (archive);
                load ();
            } else {
                throw new DocumentError.NOT_FOUND ("File does not exist");
            }
        }

        private async void read_archive (Archive.Read archive) throws DocumentError {
            var entries_cache = new Gee.ArrayList<ArchivableItem> ();

            Archive.ExtractFlags flags;
            flags = Archive.ExtractFlags.TIME;
            flags |= Archive.ExtractFlags.PERM;
            flags |= Archive.ExtractFlags.ACL;
            flags |= Archive.ExtractFlags.FFLAGS;

            unowned Archive.Entry entry;
            Archive.Result last_read_result;

            while ((last_read_result = archive.next_header (out entry)) == Archive.Result.OK) {
                debug ("Reading archive entry %s", entry.pathname ());
                uint8[] buffer = null;
                Posix.off_t offset;

                while ((last_read_result = archive.read_data_block (out buffer, out offset)) == Archive.Result.OK) {
                    string entry_path = entry.pathname ();
                    string entry_name = GLib.Path.get_basename (entry_path);
                    string group_name = GLib.Path.get_dirname (entry_path);
                    if (entry.filetype () == Archive.FileType.IFREG) {
                        switch (entry_name) {
                            case "manifest.json":
                                from_json (buffer);
                            break;
                            case "settings.json":
                                settings = new DocumentSettings.from_data (buffer);
                            break;
                            default:
                                // Everything else cached for later parsing
                                entries_cache.add (
                                    new ArchivableItem.with_props (entry_name, group_name, buffer)
                                );
                            break;
                        }
                    }
                }
            }

            if (last_read_result != Archive.Result.EOF) {
                warning ("Error: %s (%d)", archive.error_string (), archive.errno ());
                throw new DocumentError.READ (archive.error_string ());
            } else {
                if (archive.close () != Archive.Result.OK) {
                    warning ("Error: %s (%d)", archive.error_string (), archive.errno ());
                    throw new DocumentError.READ (archive.error_string ());
                }

                var chunks_iter = entries_cache.filter ((e) => {
                    return e.group != "Resource";
                });

                var resources_iter = entries_cache.filter ((e) => {
                    return e.group == "Resource";
                });

                while (chunks_iter.has_next ()) {
                    chunks_iter.next ();
                    ArchivableItem item = chunks_iter.@get ();

                    DocumentChunk chunk = yield DocumentChunk.deserialize_chunk_base_from_data (item.data, this);
                    chunks.add (chunk);
                }

                while (resources_iter.has_next ()) {
                    resources_iter.next ();
                    ArchivableItem resource = resources_iter.@get ();
                    if (resource.name.has_suffix (".text")) {
                        // SCENARIO: this is a gtk.sourcebuffer for some text chunk, find it and append it
                        var target_chunk_uuid = resource.name.substring (0, resource.name.index_of (".text"));
                        chunks.@foreach ((chunk) => {
                            if (chunk != null && chunk.uuid == target_chunk_uuid) {
                                ((TextChunkBase) chunk).load_text_data (resource.data);
                                return false;
                            } else {
                                return true;
                            }
                        });
                    }
                }
            }
        }

        /**
         * Adds a chunk to the collection, making it active by default
         */
        public virtual signal void add_chunk (owned DocumentChunk chunk) {
            chunks.add (chunk);
            debug (@"Chunk '$(chunk.title)' added to document");
        }

        public virtual signal void remove_chunk (DocumentChunk chunk) {
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
        public virtual signal bool move_chunk (DocumentChunk chunk, DocumentChunk ? before_this) {
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
