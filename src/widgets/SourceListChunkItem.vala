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

namespace Manuscript.Widgets {
    public class SourceListChunkItem : Granite.Widgets.SourceList.Item, Granite.Widgets.SourceListDragSource {
        public signal void item_should_be_deleted (SourceListChunkItem item);

        protected Models.DocumentChunk _chunk;
        public Models.DocumentChunk chunk {
            get {
                return _chunk;
            }
            construct {
                _chunk = value;
                name = chunk.title;
            }
        }

        protected Gtk.Menu? item_menu;
        protected Gtk.MenuItem lock_menu_entry;
        protected Gtk.MenuItem unlock_menu_entry;
        protected Gtk.Image lock_icon;

        public SourceListChunkItem.with_chunk (Models.DocumentChunk chunk) {
            this (chunk);
        }

        public SourceListChunkItem (Models.DocumentChunk chunk) {
            Object (
                chunk: chunk,
                editable: !chunk.locked,
                selectable: true,
                name: chunk.title
            );
        }

        construct {
            item_menu = new Gtk.Menu ();
            lock_menu_entry = new Gtk.MenuItem.with_label (_("Lock"));
            lock_menu_entry.activate.connect (() => {
                chunk.locked = true;
            });
            lock_menu_entry.no_show_all = true;

            unlock_menu_entry = new Gtk.MenuItem.with_label (_("Unlock"));
            unlock_menu_entry.activate.connect (() => {
                chunk.locked = false;
            });
            unlock_menu_entry.no_show_all = true;

            var delete_menu_entry = new Gtk.MenuItem.with_label (_("Remove"));
            delete_menu_entry.activate.connect (() => {
                item_should_be_deleted (this);
            });

            item_menu.append (lock_menu_entry);
            item_menu.append (unlock_menu_entry);
            item_menu.append (delete_menu_entry);
            item_menu.show_all ();

            lock_icon = new Gtk.Image ();
            lock_icon.gicon = new ThemedIcon ("changes-prevent");
            lock_icon.pixel_size = Gtk.IconSize.LARGE_TOOLBAR;

            edited.connect (on_edited);
            chunk.notify.connect (on_chunk_changed);

            update_ui ();
        }

        ~ SourceListChunkItem () {
            edited.disconnect (on_edited);
            if (chunk != null) {
                chunk.changed.disconnect (on_chunk_changed);
            }
        }

        public bool has_changes {
            get {
                return chunk.has_changes;
            }
        }

        private void on_edited (string new_name) {
            chunk.title = new_name;
        }

        private void on_chunk_changed () {
            update_ui ();
        }

        private void update_ui () {
            if (chunk.locked) {
                lock_menu_entry.hide ();
                unlock_menu_entry.show ();
                icon = lock_icon.gicon;
            } else {
                lock_menu_entry.show ();
                unlock_menu_entry.hide ();
                icon = null;
            }
            editable = !chunk.locked;
        }

        public override Gtk.Menu? get_context_menu () {
            return item_menu;
        }

        // Drag interface

        public bool draggable () {
            return true;
        }

        public void prepare_selection_data (Gtk.SelectionData selection_data) {
            debug (selection_data.get_text ());
        }
    }
}
