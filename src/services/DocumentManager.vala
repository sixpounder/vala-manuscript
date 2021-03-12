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

namespace Manuscript.Services {
    public class DocumentManager : Object {
        protected uint autosave_timer_id = 0;

        public signal void load (Models.Document document);
        public signal void change (Models.Document new_document);
        public virtual signal void unload (Models.Document old_document) {
            if (autosave_timer_id != 0) {
                GLib.Source.remove (autosave_timer_id);
            }

            if (settings.autosave) {
                save (true);
            }
        }
        public signal void unloaded ();
        public signal void property_change (string property_name);
        public signal void start_editing (Models.DocumentChunk chunk);
        public signal void stop_editing (Models.DocumentChunk chunk);
        public signal void selected (Models.DocumentChunk chunk);

        public signal void chunk_deleted (Models.DocumentChunk deleted_chunk);

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
        }

        public void set_current_document (owned Models.Document doc) {
            assert (doc != null);
            debug (@"Setting current document: $(doc == null ? "null" : doc.uuid)");
            if (document == null && doc != null) {
                document = doc;
                settings.last_opened_document = document.file_path;
                document.notify.connect ((pspec) => {
                    property_change (pspec.get_nick ());
                });
                _opened_chunks.clear ();
                load (document);
            } else if (doc != null && document != null && document != doc) {
                document = doc;
                settings.last_opened_document = document.file_path;
                _opened_chunks.clear ();
                document.notify.connect ((pspec) => {
                    property_change (pspec.get_nick ());
                });
                change (document);
            }
        }

        public void open_chunk (Models.DocumentChunk chunk) {
            if (!opened_chunks.contains (chunk)) {
                opened_chunks.add (chunk);
            }
            start_editing (chunk);
        }

        public void add_chunk (owned Models.DocumentChunk chunk) {
            document.add_chunk (chunk);
            if (settings.autosave) {
                queue_autosave ();
            }
        }

        public void remove_chunk (Models.DocumentChunk chunk) {
            close_chunk (chunk);
            document.remove_chunk (chunk);
            chunk_deleted (chunk);
            if (settings.autosave) {
                queue_autosave ();
            }
        }

        public void select_chunk (Models.DocumentChunk chunk) {
            selected (chunk);
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

        public void save (bool ignore_temporary = false) {
            if (document.is_temporary () && !ignore_temporary) {
                // Ask where to save this
                save_as ();
            } else {
                document.save ();
            }
        }

        public void save_as () {
            var dialog = new FileSaveDialog (window, document);
            int res = dialog.run ();
            if (res == Gtk.ResponseType.ACCEPT) {
                document.save (dialog.get_filename ());
                settings.last_opened_document = document.file_path;
            }
            dialog.destroy ();
        }

        public void queue_autosave () {
            if (autosave_timer_id != 0) {
                GLib.Source.remove (autosave_timer_id);
            }

            // Avoid trashing the disk
            autosave_timer_id = Timeout.add (1000, () => {
                autosave_timer_id = 0;
                save (true);
                return false;
            });
        }

        public void close () {
            if (document != null) {
                unload (document);
                document = null;
            }
            unloaded ();
        }
    }
}
