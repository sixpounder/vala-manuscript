/*
 * Copyright 2022 Andrea Coronese <sixpounder@protonmail.com>
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

namespace Manuscript.Services {
    //  public class DocumentManagerWorker : Object {
    //      public virtual void run () {}
    //  }

    public class SaveWorker : Object, ThreadWorker<void> {
        public weak Models.Document document { get; construct; }
        public string? path { get; construct; }
        public Models.DocumentError? save_error { get; protected set; }

        public SaveWorker (Models.Document document, string? path = null) {
            Object (
                document: document,
                path: path
            );
        }

        public void worker_run () {
            try {
                if (document != null) {
                    document.save (path);
                }
            } catch (Models.DocumentError e) {
                save_error = e;
            }
        }
    }

    public class DocumentManager : Object {
        protected uint autosave_timer_id = 0;
        protected FileMonitor? file_monitor;
        protected Services.ThreadPool ops_pool;
        protected weak Models.DocumentChunk active_chunk;

        public signal void load (Models.Document document);
        public virtual signal void unload (Models.Document old_document) {
            if (autosave_timer_id != 0) {
                GLib.Source.remove (autosave_timer_id);
            }

            stop_file_monitor ();
        }
        public signal void unloaded ();
        public signal void property_change (string property_name);
        public signal void stop_editing (Models.DocumentChunk chunk);
        public signal void backend_file_unlinked ();

        private Models.Document _document = null;
        private Gee.ArrayList<Models.DocumentChunk> _opened_chunks;
        public weak Manuscript.Application application { get; construct; }
        public weak Manuscript.Window window { get; construct; }
        public weak Services.AppSettings settings { get; private set; }

        public Models.Document document {
            get {
                return _document;
            }
            private set {
                _document = value;
            }
        }

        public bool has_document {
            get {
                return _document != null;
            }
        }

        public Gee.ArrayList<Models.DocumentChunk> opened_chunks {
            get {
                return _opened_chunks;
            }
        }

        public DocumentManager (Manuscript.Application application, Manuscript.Window window) {
            Object (
                application: application,
                window: window
            );
        }

        construct {
            settings = Services.AppSettings.get_default ();
            _opened_chunks = new Gee.ArrayList<Models.DocumentChunk> ();

            if (Services.ThreadPool.supported) {
                ops_pool = Services.ThreadPool.get_default ();
            } else {
                warning ("*** Current environment does not support threads. Application could experience problems ***");
            }
        }

        ~ DocumentManager () {
            disconnect_events ();
        }

        public async void load_from_path (string path) throws Models.DocumentError requires (path != null) {
            try {
                var doc = yield new Models.Document.from_file (path);

                // Make a temporary file to use as safety backup in case of saving errors
                //  make_backup_file_with_original(path);
                set_document (doc);
            } catch (Models.DocumentError e) {
                warning (e.message);
                throw e;
            }
        }

        [ CCode ( cname = "inner_set_document" ) ]
        private void set_document (Models.Document doc) {
            assert (doc != null);
            debug (@"Setting current document: $(doc == null ? "null" : doc.uuid)");
            if (document == null && doc != null) {
                document = doc;
                settings.last_opened_document = document.file_path;
                _opened_chunks.clear ();
            } else if (doc != null && document != null && document != doc) {
                stop_file_monitor ();
                document.settings.notify.disconnect (on_document_setting_changed);
                document = doc;
                settings.last_opened_document = document.file_path;
                _opened_chunks.clear ();
            }

            if (document != null) {
                connect_events ();
                load (document);
            }
        }

        public virtual signal void open_chunk (Models.DocumentChunk chunk) {
            if (!opened_chunks.contains (chunk)) {
                opened_chunks.add (chunk);
            }
            active_chunk = chunk;
        }

        public virtual signal void add_chunk (Models.DocumentChunk chunk) {
            document.add_chunk (chunk);
            if (settings.autosave) {
                queue_autosave ();
            }
        }

        public virtual signal void remove_chunk (Models.DocumentChunk chunk) {
            close_chunk (chunk);
            document.remove_chunk (chunk);
            //  chunk_deleted (chunk);
            if (settings.autosave) {
                queue_autosave ();
            }
        }

        public virtual signal void select_chunk (Models.DocumentChunk chunk) {
            open_chunk (chunk);
        }

        public void move_chunk (Models.DocumentChunk chunk, Models.DocumentChunk ? before_this) {
            document.move_chunk (chunk, before_this);

            if (settings.autosave) {
                queue_autosave ();
            }
        }

        public void close_chunk (Models.DocumentChunk chunk) {
            if (opened_chunks.contains (chunk)) {
                stop_editing (chunk);
                opened_chunks.remove (chunk);
            }
        }

        public Protocols.SearchResult[] search (string word) {
            return {};
        }

        // FS ops

        public void save_sync () throws Models.DocumentError {
            try {
                settings.searchbar = false;
                document.save ();
            } catch (Models.DocumentError e) {
                save_error (e);
                throw e;
            }
        }

        public async void save (bool ignore_temporary = false) {
            var search_status = settings.searchbar;
            settings.searchbar = false;
            if (document.is_temporary () && !ignore_temporary) {
                // Ask where to save this
                save_as ();
            } else {
                SourceFunc callback = save.callback;
                Mutex doc_mutex = Mutex ();
                if (ops_pool != null) {
                    doc_mutex.@lock ();
                    var wrk = new SaveWorker (document);
                    wrk.done.connect (() => {
                        if (wrk.save_error != null) {
                            critical (wrk.save_error.message);
                            // TODO: restore backup?
                        }
                        settings.searchbar = search_status;
                        Idle.add ((owned) callback);
                        doc_mutex.@unlock ();
                    });
                    ops_pool.add (wrk);
                    yield;
                } else {
                    try {
                        document.save ();
                    } catch (Models.DocumentError e) {
                        save_error (e);
                    } finally {
                        settings.searchbar = search_status;
                    }
                }
            }
        }

        public void save_as () {
            var dialog = Manuscript.Dialogs.file_save_dialog (window, document);
            var res = dialog.run ();

            if (res == Gtk.ResponseType.ACCEPT) {
                string filename = dialog.get_filename ();
                if (!filename.has_suffix (Constants.DEFAULT_FILE_EXT)) {
                    filename = filename.concat (Constants.DEFAULT_FILE_EXT);
                }

                settings.last_opened_document = document.file_path;

                if (ops_pool != null) {
                    ops_pool.add (new SaveWorker (document, filename));
                } else {
                    var search_status = settings.searchbar;
                    settings.searchbar = false;
                    try {
                        document.save (filename);
                    } catch (Models.DocumentError e) {
                        save_error (e);
                    } finally {
                        settings.searchbar = search_status;
                    }
                }
            }
            dialog.destroy ();
        }

        public void queue_autosave () {
            if (autosave_timer_id != 0) {
                GLib.Source.remove (autosave_timer_id);
            }

            // Avoid trashing the disk
            autosave_timer_id = Timeout.add (Constants.AUTOSAVE_DEBOUNCE_TIME, () => {
                autosave_timer_id = 0;
                save.begin (true);
                return false;
            });
        }

        public async void close () throws Models.DocumentError {
            if (document != null) {
                unload (document);
                if (settings.autosave) {
                    try {
                        save_sync ();
                        //  remove_backup_file_with_original (document.file_path);
                    } catch (Models.DocumentError save_error) {
                        critical (save_error.message);
                    }
                }
                document = null;
            }
            unloaded ();
        }

        protected void connect_events () {
            start_file_monitor ();
            document.settings.notify.connect (on_document_setting_changed);
            document.notify.connect ((pspec) => {
                property_change (pspec.get_nick ());
            });
        }

        private void disconnect_events () {
            if (document != null && document.settings != null) {
                document.settings.notify.disconnect (on_document_setting_changed);
            }
            stop_file_monitor ();
        }

        protected void start_file_monitor () {
            if (document != null && document.file_ref != null) {
                try {
                    file_monitor = document.file_ref.monitor (FileMonitorFlags.SEND_MOVED, null);
                    file_monitor.rate_limit = Constants.FILE_MONITOR_RATE_LIMIT;
                } catch (Error e) {
                    warning (@"Cannot monitor $(document.file_ref.get_path ())");
                    return;
                }

                file_monitor.changed.connect (on_file_monitor_event);
                debug (@"Start monitoring $(document.file_ref.get_path ())");
            }
        }

        protected void stop_file_monitor () {
            if (file_monitor != null && !file_monitor.cancelled) {
                file_monitor.changed.disconnect (on_file_monitor_event);
                file_monitor.cancel ();
                file_monitor = null;
                debug (@"Stop monitoring $(document.file_ref.get_path ())");
            }
        }

        protected void on_document_setting_changed (ParamSpec param) {
            if (settings.autosave) {
                queue_autosave ();
            }
        }

        protected void on_file_monitor_event (File file, File? other_file, FileMonitorEvent event_type) {
            debug (@"File monitor event: $(event_type.to_string ())");
            if (event_type == FileMonitorEvent.DELETED) {
                backend_file_unlinked ();
            }
        }

        public virtual signal void save_error (Models.DocumentError error) {
            critical ("Document save error: %s", error.message);
        }
    }
}
