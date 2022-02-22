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
    [ CCode (cprefix="DOCUMENT_STATE_FLAG_") ]
    public enum DocumentStateFlags {
        OK,
        BROKEN,
        ERR_LAST_SAVE
    }

    [ CCode (cprefix="DOCUMENT_ERROR_DOMAIN_") ]
    public errordomain DocumentError {
        CREATE,
        NOT_FOUND,
        READ,
        PARSE,
        SAVE,
        SERIALIZE
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
        public abstract Gee.Collection<ArchivableItem> to_archivable_entries () throws DocumentError;
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

    public class DocumentData : Object, Archivable {
        public signal void load ();
        public File? file_ref { get; protected set; }
        public string version { get; set; }
        public string uuid { get; set; }

        private string? _title;
        public string title {
            get {
                if (_title == null || _title.length == 0) {
                    return _("Untitled");
                } else {
                    return _title;
                }
            }

            set {
                _title = value;
            }
        }

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

        public Gee.Collection<ArchivableItem> to_archivable_entries () throws DocumentError {
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

    }

    public class Document : DocumentData {
        public signal void saved (string target_path);
        public signal void read_error (GLib.Error error);
        public signal void save_error (DocumentError e);
        public signal void chunk_added (DocumentChunk chunk, bool active);
        public signal void chunk_removed (DocumentChunk chunk);
        public signal void chunk_moved (DocumentChunk chunk);
        //  public signal void active_changed (DocumentChunk chunk);
        public signal void drain ();

        public DocumentStateFlags state_flags { get; protected set construct; }
        private string original_path;
        private string modified_path;
        private bool saving = false;
        private uint _load_state = DocumentLoadState.EMPTY;

        public DocumentChunk active_chunk { get; private set; }

        public bool temporary { get; set; }

        public bool has_changes {
            get {
                return chunks.any_match ((item) => item.has_changes);
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
                    return _("Untitled");
                } else {
                    return file_path != null ? GLib.Path.get_basename (file_path) : _ ("Untitled");
                }
            }
        }

        public bool has_backup {
            get {
                var file = File.new_for_path (
                    GLib.Path.build_filename (
                        file_ref.get_parent ().get_path (), @"~$(file_ref.get_basename ())"
                    )
                );

                return file.query_exists ();
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
                temporary: temporary_doc,
                state_flags: DocumentStateFlags.OK
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
        }

        public ulong save (string ? path = null) throws DocumentError {
            if (!this.saving) {
                try {
                    this.saving = true;
        
                    if (path != null) {
                        modified_path = path;
                    }
                    //  DocumentError ? encountered_error = null;
        
                    make_backup_file_with_original (file_path);
    
                    Manuscript.Models.Backend.BinaryFileBackend be = new Manuscript.Models.Backend.BinaryFileBackend ();
                    
                    File file_for_path = File.new_for_path (file_path);
                    if (file_for_path.query_exists ()) {
                        file_for_path.delete ();
                    }
    
                    FileOutputStream @out = file_for_path.create_readwrite (
                        FileCreateFlags.REPLACE_DESTINATION | FileCreateFlags.PRIVATE, null
                    ).output_stream as FileOutputStream;
    
                    ulong size = be.save (this, @out);

                    @out.close (null);

                    if (size != 0) {
                        remove_backup_file_with_original (file_path);
                    }
    
                    return size;
                } catch (Error e) {
                    critical (e.message);
                    return 0;
                } finally {
                    this.saving = false;
                }
            } else {
                return 0;
            }
        }

        public Thread<ulong> save_async (string ? path = null) {
            return new GLib.Thread<ulong> ("save_thread", () => {
                try {
                    return this.save (path);
                } catch (DocumentError e) {
                    critical (e.message);
                    return 0;
                }
            });
        }

        private async void load_from_file (string file_path) throws DocumentError {
            try {
                chunks.clear ();

                File file_for_path = File.new_for_path (file_path);

                if (file_for_path.query_exists ()) {
                    load_state = DocumentLoadState.LOADING;

                    FileIOStream ios = file_for_path.open_readwrite ();
                    var @in = ios.input_stream as FileInputStream;

                    Manuscript.Models.Backend.BinaryFileBackend be = new Manuscript.Models.Backend.BinaryFileBackend ();
                    be.read (this, @in);
                }
                else {
                    throw new DocumentError.NOT_FOUND ("File does not exist");
                }
            } catch (DocumentError e) {
                state_flags = DocumentStateFlags.BROKEN;
                throw e;
            } catch (Error e) {
                state_flags = DocumentStateFlags.BROKEN;
                throw new DocumentError.READ (e.message);
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
                chunk.index = count_chunks_by_kind (chunk.kind) - 1;
            } else {
                debug ("Moving %s before %s", chunk.title, before_this.title);
                chunk.index = before_this.index - 1;

                int idx = 0;
                iter_chunks_by_kind (chunk.kind)
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

        public Gee.Iterator<DocumentChunk> iter_chunks_with_changes () {
            return chunks.filter ((item) => {
                return item.has_changes;
            }).order_by ((a, b) => {
                return (int) (a.index - b.index);
            });
        }

        /**
         * Iterates over chunks of a specified kind, sorting them by their index
         */
        public Gee.Iterator<DocumentChunk> iter_chunks_by_kind (ChunkType kind) {
            return chunks.filter ((item) => {
                return item.kind == kind;
            }).order_by ((a, b) => {
                return (int) (a.index - b.index);
            });
        }

        /**
         * Iterates over all chunks, sorting them by their index
         */
        public Gee.Iterator<DocumentChunk> iter_chunks () {
            return chunks.order_by ((a, b) => {
                return (int) (a.index - b.index);
            });
        }

        private int count_chunks_by_kind (ChunkType kind) {
            int i = 0;
            chunks.filter ((item) => {
                return item.kind == kind;
            }).@foreach (() => {
                i++;
                return true;
            });

            return i;
        }

        public void restore_current_backup () throws Error {
            var expected_backup_path = Path.build_path (
                Path.DIR_SEPARATOR_S, file_ref.get_parent ().get_path (), @"~$(file_ref.get_basename ())"
            );
            var backup_file = File.new_for_path (expected_backup_path);
            if (backup_file.query_exists ()) {
                backup_file.copy (file_ref, GLib.FileCopyFlags.OVERWRITE);
            }
        }

        //  public Document clone () {
        //      Document clone = new Document.empty ();
        //      clone.title = this.title;
        //      clone.uuid = this.uuid;
        //      clone.version = this.version;

        //      foreach (var chunk in this.chunks) {
        //          clone.add_chunk (chunk.clone ());
        //      }

        //      return clone;
        //  }

        private void make_backup_file_with_original (string original_path) {
            if (original_path.substring (0, 1) != "~") {
                FileUtils.make_backup (original_path);
            }
        }

        private void remove_backup_file_with_original (string original_path) {
            var original_file = File.new_for_path (original_path);
            var backup = File.new_for_path (
                Path.build_path (
                    Path.DIR_SEPARATOR_S, original_file.get_path (), "~", original_file.get_basename ()
                )
            );

            if (backup.query_exists ()) {
                try {
                    backup.delete ();
                } catch (Error e) {
                    warning (e.message);
                }
            }
        }
    }
}
