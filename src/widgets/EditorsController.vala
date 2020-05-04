namespace Manuscript.Widgets {
    public class EditorsController : Gtk.Stack, Protocols.EditorViewController {

        protected bool _on_viewport = true;
        protected Services.AppSettings settings;
        protected Services.DocumentManager document_manager;
        protected Granite.Widgets.DynamicNotebook notebook;
        protected Gtk.Label editors_courtesy_view;

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

        public GLib.List<Granite.Widgets.Tab> tabs {
            get {
                return notebook.tabs;
            }
        }

        public Granite.Widgets.Tab current_tab {
            get {
                return notebook.current;
            }
        }

        public EditorsController (Manuscript.Window parent_window) {
            Object (
                parent_window: parent_window
            );

            notebook = new Granite.Widgets.DynamicNotebook ();
            notebook.add_button_visible = false;
            notebook.allow_new_window = false;
            notebook.tab_removed.connect (on_editor_closed);

            get_style_context ().add_class ("documents-notebook");
            settings = Services.AppSettings.get_default ();
            document_manager = parent_window.document_manager;
            document_manager.load.connect (on_document_set);
            document_manager.change.connect (on_document_set);
            document_manager.unload.connect (on_document_unload);
            document_manager.start_editing.connect (on_start_chunk_editing);

            on_viewport = !settings.zen;

            settings.change.connect ((key) => {
                if (key == "zen") {
                    on_viewport = !settings.zen;
                }
            });

            editors_courtesy_view = new Gtk.Label (_("Use the sidebar to open an editor"));
            editors_courtesy_view.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

            add_named (editors_courtesy_view, "editors-courtesy-view");
            add_named (notebook, "editors");

            update_ui ();
        }

        ~ EditorsController () {
            if (document_manager.document != null) {
                on_document_unload (document_manager.document);
            }

            notebook.tab_removed.disconnect (on_editor_closed);
        }

        private void on_document_set (Models.Document doc) {
            assert (doc != null);
            doc.chunk_added.connect (add_chunk);
            doc.chunk_removed.connect (remove_chunk);
            doc.active_changed.connect (select_chunk);
        }

        private void on_document_unload (Models.Document doc) {
            assert (doc != null);
            doc.chunk_added.disconnect (add_chunk);
            doc.chunk_removed.disconnect (remove_chunk);
            doc.active_changed.disconnect (select_chunk);
        }

        private void on_start_chunk_editing (Models.DocumentChunk chunk) {
            var existing_tab = get_tab_for_chunk (chunk);
            if (existing_tab == null) {
                add_chunk (chunk, true);
            } else {
                notebook.current = existing_tab;
            }
        }

        private void update_ui () {
            if (document_manager.document != null && document_manager.opened_chunks.size != 0) {
                visible_child = notebook;
            } else {
                visible_child = editors_courtesy_view;
            }
        }

        private EditorView ? get_tab_for_chunk (Models.DocumentChunk chunk) {
            EditorView? existing_tab = null;
            tabs.@foreach ((item) => {
                assert (item is EditorView);
                if (existing_tab == null && ((EditorView) item).chunk == chunk) {
                    existing_tab = (EditorView) item;
                }
            });

            return existing_tab;
        }

        // Editors events
        private void on_editor_closed () {
            update_ui ();
        }

        private void add_chunk (Models.DocumentChunk chunk, bool active = true) {
            assert (chunk != null);
            var existing_tab = get_tab_for_chunk (chunk);
            if (existing_tab == null) {
                EditorView new_tab = new EditorView (chunk);
                notebook.insert_tab (new_tab, 0);
                if (active) {
                    notebook.current = new_tab;
                    new_tab.focus_editor ();
                }
                update_ui ();
            } else {
                notebook.current = existing_tab;
                existing_tab.focus_editor ();
            }
        }

        private void remove_chunk (Models.DocumentChunk chunk) {
            assert (chunk != null);
            for (int i = 0; i < notebook.tabs.length (); i++) {
                EditorView t = (EditorView) notebook.tabs.nth (i);
                if (t.chunk == chunk) {
                    notebook.remove_tab (t);
                    return;
                }
            }
            update_ui ();
        }

        private void select_chunk (Models.DocumentChunk chunk) {
            assert (chunk != null);
            for (int i = 0; i < notebook.tabs.length (); i++) {
                EditorView t = (EditorView) notebook.tabs.nth (i);
                if (t.chunk != null && t.chunk == chunk) {
                    notebook.current = t;
                    document_manager.document.set_active (chunk);
                    return;
                }
            }
        }

        // Editor view protocol

        public unowned List<Protocols.EditorController> list_editors () {
            return (List<Protocols.EditorController>) notebook.tabs;
        }

        public Protocols.EditorController get_editor (Models.DocumentChunk chunk) {
            return get_tab_for_chunk (chunk);
        }

        public void add_editor (Models.DocumentChunk chunk) {
            add_chunk (chunk);
        }

        public void remove_editor (Models.DocumentChunk chunk) {
            remove_chunk (chunk);
        }

        public void show_editor (Models.DocumentChunk chunk) {
            select_chunk (chunk);
        }
    }
}
