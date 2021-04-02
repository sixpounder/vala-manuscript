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

    /**
     * Serves as controller for a group of `EditorView`s.
     */
    public class EditorsController : Gtk.Stack, Protocols.EditorViewController {

        protected Services.AppSettings settings;
        public weak Manuscript.Window parent_window { get; construct; }
        protected Services.DocumentManager document_manager;
        protected Manuscript.Widgets.EditorCourtesyView editors_courtesy_view;
        protected Gee.HashMap<string, Protocols.ChunkEditor> editors_cache;
        protected uint collision_counter = 0;
        protected bool _on_viewport = true;
        private bool document_loaded = false;

        public bool on_viewport {
            get {
                return _on_viewport;
            }
            set {
                _on_viewport = value;
                var style = get_style_context ();
                style.remove_class ("toggled-on");
                style.remove_class ("toggled-off");
                style.add_class (@"toggled-$(_on_viewport ? "on" : "off")");
            }
        }

        public EditorsController (Manuscript.Window parent_window) {
            Object (
                parent_window: parent_window,
                transition_type: Gtk.StackTransitionType.CROSSFADE,
                transition_duration: 200
            );
        }

        construct {
            get_style_context ().add_class ("editors-controller");

            editors_cache = new Gee.HashMap<string, Protocols.ChunkEditor> ();

            document_manager = parent_window.document_manager;
            document_manager.load.connect_after (on_document_set);
            document_manager.unload.connect_after (on_document_unload);
            document_manager.unloaded.connect_after (update_ui);
            document_manager.open_chunk.connect_after (on_start_chunk_editing);
            document_manager.stop_editing.connect_after (on_stop_chunk_editing);

            settings = Services.AppSettings.get_default ();
            on_viewport = !settings.focus_mode;
            settings.change.connect ((key) => {
                if (key == "zen") {
                    on_viewport = !settings.focus_mode;
                }
            });

            editors_courtesy_view = new Manuscript.Widgets.EditorCourtesyView (document_manager);

            add_named (editors_courtesy_view, "editors-courtesy-view");

            visible_child = editors_courtesy_view;

            show_all ();
        }

        ~ EditorsController () {
            document_manager.load.disconnect (on_document_set);
            document_manager.unload.disconnect (on_document_unload);
            document_manager.unloaded.disconnect (update_ui);
            document_manager.open_chunk.disconnect (on_start_chunk_editing);
            document_manager.stop_editing.disconnect (on_stop_chunk_editing);

            if (document_manager.document != null) {
                on_document_unload (document_manager.document);
            }
        }

        private void on_document_set (Models.Document doc) {
            assert (doc != null);
            document_loaded = true;
        }

        private void on_document_unload (Models.Document doc) {
            assert (doc != null);
            doc.chunk_added.disconnect (add_chunk);
            doc.chunk_removed.disconnect (remove_chunk);
            editors_cache.clear ();
            document_loaded = false;
        }

        private void on_start_chunk_editing (Models.DocumentChunk chunk) {
            if (document_loaded) {
                debug (@"EditorsController - Start editing chunk $(chunk.title)");
                add_editor_view_for_chunk (chunk, true);
            }
        }

        private void on_stop_chunk_editing (Models.DocumentChunk? chunk) {
            if (document_loaded) {
                debug (@"EditorsController - Stop editing chunk $(chunk.title)");
            }
        }

        // Updates various components of this widget to reflect current
        // document status
        //
        private void update_ui () {
            if (document_manager.has_document && document_manager.opened_chunks.size != 0) {
                // add_editor_view_for_chunk (document_manager.opened_chunks.first as Models.DocumentChunk, true);
                visible_child = editors_courtesy_view;
            } else {
                visible_child = editors_courtesy_view;
            }
        }

        private Protocols.ChunkEditor get_editor_view_for_chunk (Models.DocumentChunk chunk) {
            string k = build_view_id (chunk);
            return editors_cache.has_key (k) ? editors_cache.@get (k) : null;
        }

        private Protocols.ChunkEditor add_editor_view_for_chunk (Models.DocumentChunk chunk, bool active = true) {
            assert (chunk != null);
            assert (chunk.uuid != null);

            string view_id = build_view_id (chunk);
            Protocols.ChunkEditor returned_view = get_editor_view_for_chunk (chunk);

            if (returned_view == null) {
                switch (chunk.kind) {
                    case Models.ChunkType.CHAPTER:
                    case Models.ChunkType.NOTE:
                        TextEditorView new_editor = new TextEditorView (parent_window, chunk);
                        add_named (new_editor, view_id);
                        returned_view = new_editor;
                        returned_view.scroll_to_cursor ();
                    break;

                    case Models.ChunkType.CHARACTER_SHEET:
                        CharacterSheetEditor new_editor =
                            new CharacterSheetEditor (parent_window, chunk as Models.CharacterSheetChunk);
                        add_named (new_editor, view_id);
                        returned_view = new_editor;
                    break;

                    case Models.ChunkType.COVER:
                        CoverEditor new_editor =
                            new CoverEditor (parent_window, chunk as Models.CoverChunk);
                        add_named (new_editor, view_id);
                        returned_view = new_editor;
                    break;

                    default:
                        assert_not_reached ();
                }

                editors_cache.@set (view_id, returned_view);
            }

            if (active == true) {
                visible_child_name = view_id;
                returned_view.focus_editor ();
            }

            return returned_view;
        }

        private string build_view_id (Models.DocumentChunk chunk) {
            string proposed_id = @"chunk-view-$(chunk.uuid)";
            //  if (get_child_by_name (proposed_id) != null) {
            //      collision_counter++;
            //      return @"chunk-view-$(chunk.uuid)-$(collision_counter)";
            //  } else {
            //      return proposed_id;
            //  }
            return proposed_id;
        }

        private void add_chunk (Models.DocumentChunk chunk, bool active = true) {
            assert (chunk != null);
            add_editor_view_for_chunk (chunk);
        }

        private void remove_chunk (Models.DocumentChunk chunk) {
            var view = get_editor_view_for_chunk (chunk);
            var k = build_view_id (chunk);
            if (view != null) {
                remove (view as Gtk.Widget);
            }

            if (editors_cache.has_key (k)) {
                editors_cache.unset (k);
            }

            update_ui ();
        }

        public unowned Protocols.ChunkEditor? get_current_editor () {
            return null;
        }

        public Protocols.ChunkEditor? get_editor (Models.DocumentChunk chunk) {
            //  return get_tab_for_chunk (chunk);
            if (visible_child is Protocols.ChunkEditor) {
                return visible_child as Protocols.ChunkEditor;
            } else {
                return null;
            }
        }

        public void add_editor (Models.DocumentChunk chunk) {
            add_editor_view_for_chunk (chunk);
        }

        public void remove_editor (Models.DocumentChunk chunk) {
            //  remove_chunk (chunk);
        }

        public void show_editor (Models.DocumentChunk chunk) {
            //  select_chunk (chunk);
        }
    }
}
