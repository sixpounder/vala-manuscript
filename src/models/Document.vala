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
        NOT_FOUND,
        READ,
        PARSE,
        SAVE
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
        //  public abstract Archivable from_archive_entries (Gee.Collection<ArchivableItem> entries);
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

        public long save (string ? path = null) throws DocumentError {
            if (path != null) {
                modified_path = path;
            }

            DocumentError ? encountered_error = null;

            make_backup_file_with_original (file_path);

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
                if (item is Archivable) {
                    archive_items.add_all (item.to_archivable_entries ());
                }
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
                    encountered_error = new DocumentError.SAVE (archive.error_string ());
                    continue;
                }
                debug (@"Writing $(entry.pathname ()) - $(item.data.length) bytes");
                size += archive.write_data (item.data);
            }

            if (archive.close () != Archive.Result.OK) {
                critical ("Error closing archive: %s", archive.error_string ());
                encountered_error = new DocumentError.SAVE ("Could not finalize archive");
                state_flags |= DocumentStateFlags.ERR_LAST_SAVE;
            } else {
                info (@"Document saved to $file_path ($size bytes of data)");
                state_flags = DocumentStateFlags.OK;
            }

            if (encountered_error != null) {
                save_error (encountered_error);
                throw encountered_error;
            } else {
                remove_backup_file_with_original (file_path);
                chunks.@foreach ((chunk) => {
                    chunk.has_changes = false;
                    return true;
                });

                this.temporary = false;
                return (long) size;
            }
        }

        public Thread<long> save_async (string ? path = null) {
            return new GLib.Thread<long> ("save_thread", () => {
                try {
                    return this.save (path);
                } catch (DocumentError e) {
                    critical (e.message);
                    return 0;
                }
            });
        }

        private async void load_from_archive_file (string file_path) throws DocumentError {
            try {
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
            } catch (DocumentError e) {
                state_flags = DocumentStateFlags.BROKEN;
                throw e;
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
                if (entry.pathname () != "" && entry.size () != 0) {
                    debug ("Reading archive entry %s", entry.pathname ());
                    MemoryOutputStream os = new MemoryOutputStream (null);
                    uint8[] buffer = null;
                    Posix.off_t offset;

                    while (
                        (last_read_result = archive.read_data_block (out buffer, out offset)) == Archive.Result.OK
                    ) {
                        try {
                            size_t bytes_written;
                            os.write_all (buffer, out bytes_written);
                            if (os.size >= entry.size ()) {
                                os.close ();
                                break;
                            }
                        } catch (IOError e) {
                            critical (e.message);
                            try {
                                os.close ();
                            } catch (IOError skip) {
                                warning (skip.message);
                            }
                            throw new DocumentError.READ (e.message);
                        }
                    }

                    uint8[] data_copy = os.steal_data ();
                    data_copy.length = (int) os.get_data_size ();

                    string entry_path = entry.pathname ();
                    string entry_name = GLib.Path.get_basename (entry_path);
                    string group_name = GLib.Path.get_dirname (entry_path);
                    if (entry.filetype () == Archive.FileType.IFREG) {
                        switch (entry_name) {
                            case "manifest.json":
                                from_json (data_copy);
                            break;
                            case "settings.json":
                                settings = new DocumentSettings.from_data (data_copy);
                            break;
                            default:
                                // Everything else cached for later parsing
                                entries_cache.add (
                                    new ArchivableItem.with_props (entry_name, group_name, data_copy)
                                );
                            break;
                        }
                    }
                } else {
                    warning ("Archive entry %s ignored due to null size", entry.gname ());
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

                    DocumentChunk chunk = yield DocumentChunk.new_from_data (item.data, this);
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
                                ((TextChunk) chunk).store_raw_data (resource.data);
                                return false;
                            } else {
                                return true;
                            }
                        });
                    } else if (
                        resource.name.has_suffix (".png") ||
                        resource.name.has_suffix (".jpeg") ||
                        resource.name.has_suffix (".jpg")
                    ) {
                        // SCENARIO: this is a cover image for some cover chunk
                        var target_chunk_uuid = resource.name.substring (0, resource.name.index_of (".png"));
                        chunks.@foreach ((chunk) => {
                            if (chunk != null && chunk.uuid == target_chunk_uuid) {
                                //  debug (chunk.uuid);
                                CoverChunk cover_chunk = chunk as CoverChunk;
                                cover_chunk.load_cover_from_stream.begin (
                                    new MemoryInputStream.from_data (resource.data)
                                );
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
