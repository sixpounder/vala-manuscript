/*
 * Copyright 2020 Andrea Coronese <sixpounder@protonmail.com>
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

        protected bool _on_viewport = true;
        protected Services.AppSettings settings;
        protected Services.DocumentManager document_manager;
        protected Gtk.Label editors_courtesy_view;
        protected Gtk.Overlay editor_view_wrapper;
        protected List<EditorView> editors_cache;

        public weak Manuscript.Window parent_window { get; construct; }

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
                transition_type: Gtk.StackTransitionType.CROSSFADE
            );
        }

        construct {
            get_style_context ().add_class ("editors-controller");
            
            editors_cache = new List<EditorView> ();

            document_manager = parent_window.document_manager;
            document_manager.load.connect (on_document_set);
            document_manager.change.connect (on_document_set);
            document_manager.unload.connect (on_document_unload);
            document_manager.unloaded.connect (update_ui);
            document_manager.selected.connect (on_start_chunk_editing);
            document_manager.start_editing.connect (on_start_chunk_editing);
            document_manager.stop_editing.connect (on_stop_chunk_editing);

            settings = Services.AppSettings.get_default ();
            on_viewport = !settings.zen;
            settings.change.connect ((key) => {
                if (key == "zen") {
                    on_viewport = !settings.zen;
                }
            });

            editors_courtesy_view = new Gtk.Label (_("Select something to edit"));
            editors_courtesy_view.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

            editor_view_wrapper = new Gtk.Overlay ();
            editor_view_wrapper.get_style_context().add_class("editor-view-wrapper");
            editor_view_wrapper.show_all ();

            add_named (editors_courtesy_view, "editors-courtesy-view");
            add_named (editor_view_wrapper, "editor-view");

            visible_child = editors_courtesy_view;

            show_all ();
        }

        ~ EditorsController () {
            if (document_manager.document != null) {
                on_document_unload (document_manager.document);
            }
        }

        private void on_document_set (Models.Document doc) {
            if (doc != null) {
                doc.chunk_added.connect (add_chunk);
                doc.chunk_removed.connect (remove_chunk);
                doc.active_changed.connect (select_chunk);
            }
        }

        private void on_document_unload (Models.Document doc) {
            assert (doc != null);
            doc.chunk_added.disconnect (add_chunk);
            doc.chunk_removed.disconnect (remove_chunk);
            doc.active_changed.disconnect (select_chunk);
            editors_cache = new List<EditorView> ();
            update_ui ();
        }

        private void on_start_chunk_editing (Models.DocumentChunk chunk) {
            debug(@"EditorsController - Start editing chunk $(chunk.uuid)");
            visible_child = editor_view_wrapper;
            add_editor_view_for_chunk (chunk, true);
        }

        private void on_stop_chunk_editing (Models.DocumentChunk? chunk) {
            debug(@"EditorsController - Stop editing chunk $(chunk.uuid)");
            var get_editor_view_for_chunk = get_editor_view_for_chunk (chunk);
            if (get_editor_view_for_chunk == null) {
                // remove_editor (chunk);
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

        private EditorView? get_editor_view_for_chunk (Models.DocumentChunk chunk) {
            EditorView? existing_view = null;
            editors_cache.@foreach((view) => {
               if (view.chunk == chunk) {
                   existing_view = view;
               }
            });
            return existing_view;
        }

        private EditorView add_editor_view_for_chunk (Models.DocumentChunk chunk, bool active = true) {
            assert (chunk != null);
            assert (chunk.uuid != null);
            var existing_child = get_editor_view_for_chunk (chunk);
            EditorView returned_view;
            if (existing_child == null) {
                EditorView new_editor = new EditorView (parent_window, chunk);
                editors_cache.append (new_editor);
                returned_view = new_editor;
            } else {
                returned_view = existing_child as EditorView;
            }

            if (active == true) {
                if (editor_view_wrapper.get_child () != null) {
                    editor_view_wrapper.remove (editor_view_wrapper.get_child ());
                }
                editor_view_wrapper.child = returned_view;
                editor_view_wrapper.show_all();
            }

            return returned_view;
        }

        // Editors events
        private void on_editor_closed () {
            update_ui ();
        }

        // private void on_tab_switched (Granite.Widgets.Tab? old_tab, Granite.Widgets.Tab new_tab) {
        //     document_manager.select_chunk ((new_tab as Protocols.EditorController).chunk);
        // }

        private void add_chunk (Models.DocumentChunk chunk, bool active = true) {
            assert (chunk != null);
            add_editor_view_for_chunk (chunk);
        }

        private void remove_chunk (Models.DocumentChunk chunk) {
        //      assert (chunk != null);0
        //      for (int i = 0; i < notebook.tabs.length (); i++) {
        //          if (notebook.tabs.nth (i) != null) {
        //              var editor = (EditorView) notebook.tabs.nth (i);
        //              if (editor != null && editor.chunk == chunk) {
        //                  notebook.remove_tab (editor);
        //                  return;
        //              }
        //          }
        //      }
            update_ui ();
        }

        private void select_chunk (Models.DocumentChunk chunk) {
        //      assert (chunk != null);
        //      for (int i = 0; i < notebook.tabs.length (); i++) {
        //          //  var t = notebook.tabs.nth (i);
        //          if (notebook.tabs.nth (i) != null) {
        //              var editor = (EditorView) notebook.tabs.nth (i);
        //              if (editor.chunk != null && editor.chunk == chunk) {
        //                  notebook.current = editor;
        //                  document_manager.document.set_active (chunk);
        //                  return;
        //              }
        //          }
        //      }
            assert (chunk != null);
            add_editor_view_for_chunk (chunk);
        }

        // Editor view protocol

        //  public List<weak Protocols.EditorController>? list_editors () {
        //      return get_children ();
        //  }

        public unowned Protocols.EditorController? get_current_editor () {
            return null;
        }

        public Protocols.EditorController? get_editor (Models.DocumentChunk chunk) {
            //  return get_tab_for_chunk (chunk);
            return editor_view_wrapper.get_child () as Protocols.EditorController;
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
