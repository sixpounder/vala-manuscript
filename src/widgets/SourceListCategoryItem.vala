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
            //  user_moved_item.connect_after (on_child_moved);
        }

        ~ SourceListCategoryItem () {
            child_chunks.clear ();
            child_added.disconnect (on_child_added);
            child_removed.disconnect (on_child_removed);
            //  user_moved_item.disconnect (on_child_moved);
        }

        private void on_child_added (Granite.Widgets.SourceList.Item item) {
            var it = item as SourceListChunkItem;
            child_chunks.add (it);
            it.item_should_be_deleted.connect ((item) => {
                remove (item);
                document_manager.remove_chunk (it.chunk);
            });
        }

        private void on_child_removed (Granite.Widgets.SourceList.Item item) {
            debug ("Source list removed chunk item");
            var it = item as SourceListChunkItem;
            child_chunks.remove (it);
        }

        private void on_child_moved (Granite.Widgets.SourceList.Item moved) {
            assert (moved != null);
            if (moved != null) {
                var moved_entry = moved as SourceListChunkItem;
                assert (moved_entry.chunk != null);
                if (moved_entry.chunk != null && moved_entry.chunk.kind == category_type) {
                    SourceListChunkItem next_item = item_after (moved_entry) as SourceListChunkItem;
                    Manuscript.Models.DocumentChunk next_chunk = next_item != null ? next_item.chunk : null;
                    debug (@"*** Item moved in list: $(moved_entry.chunk.title) before $(next_chunk != null ? next_chunk.title : "nothing") ***");
                    document_manager.move_chunk (moved_entry.chunk, next_chunk);
                } else {
                    warning ("Could not move item (item has no chunk associated)");
                }
            } else {
                warning ("Could not move item (NULL)");
            }
        }

        /**
         * Finds the `Granite.Widgets.SourceList.Item` that lies before `item` (if any)
         */
        public Granite.Widgets.SourceList.Item ? item_before (Granite.Widgets.SourceList.Item item) {
            Granite.Widgets.SourceList.Item found = null;
            if (children.size == 1) {
                found = null;
            } else {
                var iter = children.iterator ();
                Granite.Widgets.SourceList.Item last_checked_item = null;
                while (iter.has_next ()) {
                    iter.next ();
                    var i = iter.@get ();
                    if (i == item) {
                        found = last_checked_item;
                        break;
                    } else {
                        last_checked_item = i;
                        continue;
                    }
                }
            }

            return found;
        }

        /**
         * Finds the `Granite.Widgets.SourceList.Item` that lies after `item` (if any)
         */
         public Granite.Widgets.SourceList.Item ? item_after (Granite.Widgets.SourceList.Item item) {
            Granite.Widgets.SourceList.Item found = null;
            if (children.size == 0) {
                found = null;
            } else {
                var iter = children.iterator ();
                while (iter.has_next ()) {
                    iter.next ();
                    var i = iter.@get ();
                    if (i == item) {
                        // Next item is the item we want to return
                        if (iter.has_next ()) {
                            iter.next ();
                            found = iter.@get ();
                        } else {
                            found = null;
                        }

                        break;
                    }
                }
            }

            return found;
        }

        public bool allow_dnd_sorting () {
            return true;
        }

        public int compare (Granite.Widgets.SourceList.Item a, Granite.Widgets.SourceList.Item b) {
            return 0;
        }
    }
}
