namespace Manuscript.Models.Backend {
    public interface Backend {
        public abstract async ulong save (Document document, OutputStream @out) throws DocumentError;
        public abstract async Document read (InputStream @in) throws DocumentError;
    }

    public class ArchiveBackend : Object, Backend {
        public async ulong save (Document document, OutputStream @out) throws DocumentError {
            return 0;
        }
        public async Document read (InputStream @in) throws DocumentError {
            uint8[] archive_buffer = {};
            size_t bytes_read;
            try {
                yield @in.read_all_async (archive_buffer, Priority.DEFAULT, null, out bytes_read);
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

            return yield this.read_archive (archive);
        }

        private async Document read_archive (Archive.Read archive) throws DocumentError {
            Document document;

            try {
                document = new Document.empty ();
            } catch (Error e) {
                throw new DocumentError.CREATE ("Cannot create empty document");
            }

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
                                yield manifest_from_json (document, data_copy);
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

                    DocumentChunk chunk = yield DocumentChunk.new_from_data (item.data, document);
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

        public async void manifest_from_json (Document parent_document, uint8[] data) throws DocumentError {
            var parser = new Json.Parser ();
            //  SourceFunc callback = from_json.callback;
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
    }

    struct Manifest {
        string version;
        string uuid;
        string title;

        public size_t size () {
            return version.data.length + uuid.data.length + title.data.length;
        }
    }

    struct ChunkHeader {
        size_t chunk_size;
    }

    public class BinaryFileBackend : Object, Backend {
        public async ulong save (Document document, OutputStream @out) throws DocumentError {
            var version = document.version;
            var uuid = document.uuid;
            var title = document.title;
            var chunks = document.chunks;

            Manifest manifest = Manifest () {
                version = version,
                uuid = uuid,
                title = title
            };

            Prelude prelude = Prelude () {
                manifest_ln = manifest.size (),
            };

            size_t bytes_written;
            size_t bytes_written_all = 0;
            size_t chunks_bytes_written = 0;
            yield @out.write_all_async ((uint8[]) prelude, Priority.DEFAULT, null, out bytes_written);
            bytes_written_all += bytes_written;
            yield @out.write_all_async ((uint8[]) manifest, Priority.DEFAULT, null, out bytes_written);
            bytes_written_all += bytes_written;

            chunks.foreach (chunk => {
                var entries = chunk.to_archivable_entries ();
                entries.foreach (entry => {
                    size_t entry_bytes_written;

                    ChunkHeader head = ChunkHeader () {
                        chunk_size = entry.data.length
                    };

                    @out.write_all ((uint8[]) head, out entry_bytes_written, null);
                    chunks_bytes_written += entry_bytes_written;
                    bytes_written_all += entry_bytes_written;

                    @out.write_all (entry.data, out entry_bytes_written, null);
                    chunks_bytes_written += entry_bytes_written;
                    bytes_written_all += entry_bytes_written;
                    return true;
                });
                return true;
            });

            return bytes_written_all;
        }
        public async Document read (InputStream @in) throws DocumentError {
            return new Document.empty ();
        }
    }
}
