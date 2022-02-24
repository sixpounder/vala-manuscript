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

namespace Manuscript.Widgets {
    public class SourceListCategoryItem :
        Granite.Widgets.SourceList.ExpandableItem,
        Granite.Widgets.SourceListSortable {

        public Gee.ArrayList<SourceListChunkItem> child_chunks { get; private set; }
        public Models.ChunkType category_type { get; private set; }
        public weak Services.DocumentManager document_manager { get; set; }

        public SourceListCategoryItem (string name = "", Models.ChunkType category_type) {
            base (name);
            this.category_type = category_type;
        }

        construct {
            child_chunks = new Gee.ArrayList<SourceListChunkItem> ();
            child_added.connect (on_child_added);
            child_removed.connect (on_child_removed);
        }

        ~ SourceListCategoryItem () {
            child_added.disconnect (on_child_added);
            child_removed.disconnect (on_child_removed);
            child_chunks.clear ();
        }

        private void on_child_added (Granite.Widgets.SourceList.Item item) {
            var it = item as SourceListChunkItem;
            child_chunks.add (it);
            it.item_should_be_deleted.connect (on_item_should_be_deleted);
        }

        private void on_item_should_be_deleted (SourceListChunkItem item) {
            document_manager.remove_chunk (item.chunk);
            item.item_should_be_deleted.disconnect (on_item_should_be_deleted);
            remove (item);
        }

        private void on_child_removed (Granite.Widgets.SourceList.Item item) {
            debug ("Source list removed chunk item");
            var it = item as SourceListChunkItem;
            child_chunks.remove (it);
        }

        public bool allow_dnd_sorting () {
            return true;
        }

        public int compare (Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b) {
            return 0;
        }
    }
}
