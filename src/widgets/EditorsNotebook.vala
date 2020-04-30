namespace Manuscript.Widgets {
    public class EditorsNotebook : Gtk.Bin {

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

        public EditorsNotebook (Manuscript.Window parent_window) {
            Object (
                parent_window: parent_window
            );

            notebook = new Granite.Widgets.DynamicNotebook ();
            notebook.add_button_visible = false;
            notebook.allow_new_window = false;

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

            editors_courtesy_view = new Gtk.Label ("Use the sidebar to open an editor");
            //  editors_courtesy_view.get_style_context ().add_class (Granite.STYLE_CLASS_WELCOME);
            editors_courtesy_view.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);

            update_ui ();
        }

        ~ EditorsNotebook () {
            if (document_manager.document != null) {
                on_document_unload (document_manager.document);
            }
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
            if (get_child () != null) {
                remove (get_child ());
            }
            if (document_manager.document != null && document_manager.opened_chunks.size != 0) {
                add (notebook);
            } else {
                add (editors_courtesy_view);
            }

            show_all ();
        }

        private EditorTab ? get_tab_for_chunk (Models.DocumentChunk chunk) {
            EditorTab? existing_tab = null;
            tabs.@foreach ((item) => {
                assert (item is EditorTab);
                if (existing_tab == null && ((EditorTab) item).chunk == chunk) {
                    existing_tab = (EditorTab) item;
                }
            });

            return existing_tab;
        }

        public void add_chunk (Models.DocumentChunk chunk, bool active = true) {
            assert (chunk != null);
            EditorTab new_tab = new EditorTab (chunk);
            notebook.insert_tab (new_tab, 0);
            if (active) {
                notebook.current = new_tab;
            }
            update_ui ();
        }

        public void remove_chunk (Models.DocumentChunk chunk) {
            assert (chunk != null);
            for (int i = 0; i < notebook.tabs.length (); i++) {
                EditorTab t = (EditorTab) notebook.tabs.nth (i);
                if (t.chunk == chunk) {
                    notebook.remove_tab (t);
                    return;
                }
            }
            update_ui ();
        }

        public void select_chunk (Models.DocumentChunk chunk) {
            assert (chunk != null);
            for (int i = 0; i < notebook.tabs.length (); i++) {
                EditorTab t = (EditorTab) notebook.tabs.nth (i);
                if (t.chunk != null && t.chunk == chunk) {
                    notebook.current = t;
                    document_manager.document.set_active (chunk);
                    return;
                }
            }
        }
    }
}
