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

    public class Sidebar : Gtk.Box {
        protected Manuscript.Widgets.DocumentSourceList root_list;
        protected Manuscript.Widgets.SourceListCategoryItem covers_root;
        protected Manuscript.Widgets.SourceListCategoryItem chapters_root;
        protected Manuscript.Widgets.SourceListCategoryItem characters_root;
        protected Manuscript.Widgets.SourceListCategoryItem notes_root;

        public weak Services.DocumentManager document_manager { get; private set; }
        public weak Manuscript.Window parent_window { get; construct; }

        public Sidebar (Manuscript.Window parent) {
            Object (
                orientation: Gtk.Orientation.VERTICAL,
                homogeneous: false,
                width_request: 250,
                hexpand: true,
                vexpand: true,
                parent_window: parent
            );
        }

        construct {
            document_manager = ((Manuscript.Window) parent_window).document_manager;
            document_manager.load.connect_after (on_document_set);
            document_manager.unload.connect_after (on_document_unload);
            document_manager.open_chunk.connect_after (on_start_edit);
            document_manager.select_chunk.connect_after (on_start_edit);
            document_manager.add_chunk.connect_after (on_chunk_added);

            build_ui ();
        }

        ~ Sidebar () {
            document_manager.load.disconnect (on_document_set);
            document_manager.unload.disconnect (on_document_unload);
            document_manager.open_chunk.disconnect (on_start_edit);
            document_manager.select_chunk.disconnect (on_start_edit);
            document_manager.add_chunk.disconnect (on_chunk_added);
        }

        public Models.Document document {
            get {
                return document_manager.document;
            }
        }

        private void build_ui () {
            // One expandable items per category
            covers_root = new SourceListCategoryItem (_("Covers"), Models.ChunkType.COVER);
            covers_root.document_manager = document_manager;
            covers_root.user_moved_item.connect (on_item_moved);

            chapters_root = new SourceListCategoryItem (_("Chapters"), Models.ChunkType.CHAPTER);
            chapters_root.document_manager = document_manager;
            chapters_root.user_moved_item.connect (on_item_moved);

            characters_root = new SourceListCategoryItem ("Characters sheets", Models.ChunkType.CHARACTER_SHEET);
            characters_root.document_manager = document_manager;
            characters_root.user_moved_item.connect (on_item_moved);

            notes_root = new SourceListCategoryItem (_("Notes"), Models.ChunkType.NOTE);
            notes_root.document_manager = document_manager;
            notes_root.user_moved_item.connect (on_item_moved);

            root_list = new DocumentSourceList ();

            var root = root_list.root;

#if CHUNK_COVER
            root.add (covers_root);
#endif

#if CHUNK_CHAPTER
            root.add (chapters_root);
#endif

#if CHUNK_CHARACTER_SHEET
            root.add (characters_root);
#endif

#if CHUNK_NOTE
            root.add (notes_root);
#endif
            root_list.item_selected.connect (on_item_selected);

            pack_start (root_list);

            show_all ();
        }

        public void reset_tree (Models.Document? doc = null) {
            chapters_root.clear ();
            characters_root.clear ();
            notes_root.clear ();
            covers_root.clear ();
            if (doc != null) {
                var it = doc.iter_chunks ();
                while (it.next ()) {
                    var item = it.@get ();
                    debug (@"Adding $(item.title)");
                    add_chunk (item, false);
                }

                covers_root.expand_all ();
                chapters_root.expand_all ();
                characters_root.expand_all ();
                notes_root.expand_all ();
            }
        }

        private void on_document_set (Models.Document doc) {
            assert (doc != null);
            reset_tree (doc);
        }

        private void on_document_unload (Models.Document doc) {
            assert (doc != null);
            reset_tree (null);
        }

        private void on_chunk_added (Models.DocumentChunk chunk) {
            add_chunk (chunk);
        }

        private void on_item_selected (Granite.Widgets.SourceList.Item? item) {
            if (item != null && item is SourceListChunkItem) {
                select_chunk (((SourceListChunkItem) item).chunk);
            }
        }

        public SourceListChunkItem? find_node (Models.DocumentChunk chunk) {
            assert (chunk != null);
            Granite.Widgets.SourceList.ExpandableItem root_node;
            switch (chunk.kind) {
                case Models.ChunkType.CHAPTER:
                    root_node = chapters_root;
                    break;
                case Models.ChunkType.CHARACTER_SHEET:
                    root_node = characters_root;
                    break;
                case Models.ChunkType.COVER:
                    root_node = covers_root;
                    break;
                case Models.ChunkType.NOTE:
                    root_node = notes_root;
                    break;
                default:
                    assert_not_reached ();
            }

            var it = root_node.children.iterator ();
            SourceListChunkItem found_item = null;
            while (it.next ()) {
                SourceListChunkItem item = it.@get () as SourceListChunkItem;
                if (item.chunk == chunk) {
                    found_item = item;
                    break;
                }
            }

            return found_item;
        }

        public void add_chunk (Models.DocumentChunk chunk, bool active = true) {
            assert (chunk != null);
            SourceListChunkItem item_to_add = new SourceListChunkItem.with_chunk (chunk);

            Granite.Widgets.SourceList.ExpandableItem root_node;
            switch (chunk.kind) {
                case Models.ChunkType.CHAPTER:
                    root_node = chapters_root;
                    break;
                case Models.ChunkType.CHARACTER_SHEET:
                    root_node = characters_root;
                    break;
                case Models.ChunkType.NOTE:
                    root_node = notes_root;
                    break;
                case Models.ChunkType.COVER:
                    root_node = covers_root;
                    break;
                default:
                    assert_not_reached ();
            }

            root_node.add (item_to_add);

            if (active) {
                root_list.scroll_to_item (item_to_add);
                root_list.start_editing_item (item_to_add);
            }
        }

        public void remove_chunk (Models.DocumentChunk chunk) {
            assert (chunk != null);
        }

        public void select_chunk (Models.DocumentChunk chunk) {
            assert (chunk != null);
            document_manager.open_chunk (chunk);
        }

        public void on_start_edit (Models.DocumentChunk chunk) {
            SourceListChunkItem node = find_node (chunk);
            if (node != null) {
                root_list.selected = node;
                root_list.scroll_to_item (node);
            }
        }

        protected void on_item_moved (Granite.Widgets.SourceList.Item moved) {
            SourceListChunkItem moved_item = moved as SourceListChunkItem;
            Granite.Widgets.SourceList.Item? next = root_list.get_next_item (moved_item);
            Manuscript.Models.DocumentChunk next_chunk = next == null ? null : ((SourceListChunkItem) next).chunk;
            document_manager.move_chunk (moved_item.chunk, next_chunk);

            // Select and scroll to the moved item to avoid confusion
            root_list.selected = moved_item;
            root_list.scroll_to_item (moved_item);
        }
    }
}
