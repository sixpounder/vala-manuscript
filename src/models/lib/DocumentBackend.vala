namespace Manuscript.Models.Backend {
    public interface Backend {
        public abstract ulong save (Document document, OutputStream @out) throws DocumentError;
        public abstract Document read (Document document, InputStream @in) throws DocumentError;
    }

    public class ArchiveBackend : Object, Backend {
        public ulong save (Document document, OutputStream @out) throws DocumentError {
            return 0;
        }
        public Document read (Document document, InputStream @in) throws DocumentError {
            uint8[] archive_buffer = {};
            size_t bytes_read;
            try {
                @in.read_all (archive_buffer, out bytes_read);
            } catch (Error e) {
                throw new DocumentError.READ ("E_STREAM");
            }

            Archive.Read archive = new Archive.Read ();
            archive.support_format_all ();
            archive.support_filter_gzip ();
            if (archive.open_memory (archive_buffer) != Archive.Result.OK) {
                critical (
                    "Error opening stream: %s (%d)",
                    archive.error_string (),
                    archive.errno ()
                );
                throw new DocumentError.READ (archive.error_string ());
            }

            return this.read_archive (document, archive);
        }

        private Document read_archive (Document document, Archive.Read archive) throws DocumentError {
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
                                manifest_from_json (document, data_copy);
                            break;
                            case "settings.json":
                                document.settings = new DocumentSettings.from_data (data_copy);
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

                    DocumentChunk chunk = DocumentChunk.new_from_data (item.data, document);
                    document.chunks.add (chunk);
                }

                while (resources_iter.has_next ()) {
                    resources_iter.next ();
                    ArchivableItem resource = resources_iter.@get ();
                    if (resource.name.has_suffix (".text")) {
                        // SCENARIO: this is a gtk.sourcebuffer for some text chunk, find it and append it
                        var target_chunk_uuid = resource.name.substring (0, resource.name.index_of (".text"));
                        document.chunks.@foreach ((chunk) => {
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
                        document.chunks.@foreach ((chunk) => {
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

            return document;
        }

        public void manifest_from_json (Document parent_document, uint8[] data) throws DocumentError {
            var parser = new Json.Parser ();
            try {
                parser.load_from_stream (new MemoryInputStream.from_data (data, null), null);
            } catch (Error error) {
                throw new DocumentError.PARSE (@"Cannot parse manuscript file: $(error.message)");
            }

            var root_object = parser.get_root ().get_object ();

            if (root_object.has_member ("version")) {
                parent_document.version = root_object.get_string_member ("version");
            } else {
                parent_document.version = "1.0";
            }

            if (root_object.has_member ("uuid")) {
                parent_document.uuid = root_object.get_string_member ("uuid");
            } else {
                info ("Document has no uuid, generating one now");
                parent_document.uuid = GLib.Uuid.string_random ();
            }

            parent_document.title = root_object.get_string_member ("title");
        }
    }

    struct Prelude {
        public size_t manifest_ln;
        public int chunks_n;
    }

    public class BinaryFileBackend : Object, Backend {
        public ulong save (Document document, OutputStream output_stream) throws DocumentError {
            try {
                DocumentOutputStream @out = new DocumentOutputStream (output_stream);

                var version = document.version;
                var uuid = document.uuid;
                var title = document.title;
                var chunks = document.chunks;
                var settings = document.settings;
    
                Prelude prelude = Prelude () {
                    manifest_ln = version.data.length + uuid.data.length + title.data.length + 3,
                    chunks_n = chunks.size
                };

                debug ("Prelude size: %lu", sizeof (Prelude));
    
                size_t bytes_written;
                size_t bytes_written_all = 0;
                size_t chunks_bytes_written = 0;

                uint8[] prelude_buffer = (uint8[]) prelude;
                prelude_buffer.length = (int) sizeof (Prelude);
                @out.write_all (prelude_buffer, out bytes_written);
                bytes_written_all += bytes_written;

                @out.write_all (version.data, out bytes_written);
                bytes_written_all += bytes_written;
                @out.write_all ({ '\0' }, out bytes_written);
                bytes_written_all += bytes_written;

                @out.write_all (uuid.data, out bytes_written);
                bytes_written_all += bytes_written;
                @out.write_all ({ '\0' }, out bytes_written);
                bytes_written_all += bytes_written;

                @out.write_all (title.data, out bytes_written);
                bytes_written_all += bytes_written;
                @out.write_all ({ '\0' }, out bytes_written);
                bytes_written_all += bytes_written;

                var settings_data = settings.to_archivable_entries ().to_array ()[0];
                @out.write_ulong (settings_data.data.length, out bytes_written);
                bytes_written_all += bytes_written;
    
                @out.write_all (settings_data.data, out bytes_written, null);
                bytes_written_all += bytes_written;

                @out.write_all ({ '\0' }, out bytes_written);
                bytes_written_all += bytes_written;
    
                foreach (var chunk in chunks) {

                    // Each chunk may yield multiple archivable entities
                    var entries = chunk.to_archivable_entries ();

                    @out.write_ulong (entries.size, out bytes_written);
                    bytes_written_all += bytes_written;

                    // Write them one by one
                    foreach (var entry in entries) {
                        size_t entry_bytes_written;
    
                        @out.write_ulong (entry.data.length, out entry_bytes_written);
                        chunks_bytes_written += entry_bytes_written;
                        bytes_written_all += entry_bytes_written;
    
                        @out.write_all (entry.data, out entry_bytes_written, null);
                        chunks_bytes_written += entry_bytes_written;
                        bytes_written_all += entry_bytes_written;
                    }
                }
    
                @out.flush (null);
                return bytes_written_all;
            } catch (Error e) {
                throw new DocumentError.SAVE (e.message);
            }
        }
        public Document read (Document document, InputStream input_stream) throws DocumentError {
            try {
                DocumentInputStream @in = new DocumentInputStream (input_stream);
                Bytes prelude_bytes = @in.read_bytes (sizeof (Prelude), null);
                Prelude* prelude = prelude_bytes.get_data ();

                debug ("Prelude says manifest is %lu bytes long", prelude.manifest_ln);
                debug ("Prelude says %lu chunks are expected", prelude.chunks_n);

                uint8[] version = @in.read_until('\0');
                uint8[] uuid = @in.read_until('\0');
                uint8[] title = @in.read_until('\0');

                document.title = (string) title;
                document.version = (string) version;
                document.uuid = (string) uuid;

                ulong settings_size = @in.read_ulong ();
                uint8[] settings_data = @in.read_bytes (settings_size).get_data ();
                document.settings = new DocumentSettings.from_data (settings_data);

                // Skip delimiter between heading and chunks sections
                @in.skip (sizeof (uint8));

                int chunks_counter = prelude.chunks_n;

                while (chunks_counter > 0) {
                    var next_chunk_entries_count = @in.read_ulong ();

                    // First entry is always the chunk itself
                    var next_entry_size = @in.read_ulong ();
                    uint8[] chunk_data = @in.read_bytes (next_entry_size).get_data ();
                    var chunk = DocumentChunk.new_from_data (chunk_data, document);

                    // For certain kind of chunks there are additional entries that must be processed
                    if (next_chunk_entries_count > 1) {
                        var next_subentry_size = @in.read_ulong ();

                        uint8[] subentry_buffer = new uint8[next_subentry_size];
                        size_t bytes_read;
                        @in.read_all (subentry_buffer, out bytes_read);

                        if (chunk.kind == ChunkType.CHAPTER || chunk.kind == ChunkType.NOTE) {
                            // For these kind of chunks this entry is the text buffer
                            if (subentry_buffer != null) {
                                ((TextChunk) chunk).set_raw (subentry_buffer);
                            } else {
                                warning ("Tried to set text chunk raw buffer but had null value");
                            }
                        }
                    }
                    document.add_chunk (chunk);
                    chunks_counter --;
                }

                return document;
                
            } catch (Error e) {
                throw new DocumentError.READ (e.message);
            }
        }
    }

    public class DocumentInputStream : InputStream {
        public InputStream inner { get; construct; }

        public DocumentInputStream (InputStream inner) {
            Object (
                inner: inner
            );
        }

        public override ssize_t read (uint8[] buffer, GLib.Cancellable? cancellable) throws IOError {
            return inner.read (buffer, cancellable);
        }

        public override bool close (GLib.Cancellable? cancellable) throws IOError {
            return inner.close (cancellable);
        }

        public ulong read_ulong () throws Error {
            uint8* long_bytes = inner.read_bytes (sizeof (ulong)).get_data ();
            return (ulong) *long_bytes;
        }

        public uint8[] read_until (char marker) throws Error {
            return Utils.Streams.read_until (inner, marker);
        }

        public uint8[] read_until_sequence (uint8[] marker) throws Error {
            return Utils.Streams.read_until_sequence (inner, marker);
        }
    }

    public class DocumentOutputStream : OutputStream {
        public OutputStream inner { get; construct; }

        public DocumentOutputStream (OutputStream inner) {
            Object (
                inner: inner
            );
        }

        public override bool close (GLib.Cancellable? cancellable) throws IOError {
            return inner.close (cancellable);
        }

        public override ssize_t write (uint8[] buffer, GLib.Cancellable? cancellable) throws IOError {
            return inner.write (buffer, cancellable);
        }

        public size_t write_ulong (ulong value, out size_t bytes_written, GLib.Cancellable? cancellable = null) throws Error {
            uint8[] value_pointer = (uint8[]) value;
            value_pointer.length = (int) sizeof (ulong);
            inner.write_all (value_pointer, out bytes_written, cancellable);

            return bytes_written;
        }

        public size_t write_ptr (void* buffer, int size, out size_t bytes_written, GLib.Cancellable? cancellable = null) throws Error {
            uint8[] buffer_data = (uint8[]) buffer;
            buffer_data.length = size;
            inner.write_all (buffer_data, out bytes_written, cancellable);
            return bytes_written;
        }
    }
}
