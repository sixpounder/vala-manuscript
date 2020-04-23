namespace Manuscript {
    public class DocumentsNotebook : Granite.Widgets.DynamicNotebook {

        protected bool _on_viewport = true;
        protected Services.AppSettings settings;
        protected Services.DocumentManager documents_manager;

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

        public DocumentsNotebook () {
            Object (
                add_button_visible: false,
                allow_new_window: false
            );

            add_button_visible = false;

            documents_manager = Services.DocumentManager.get_default ();

            documents_manager.document.chunk_added.connect (add_chunk);

            documents_manager.document.chunk_removed.connect (remove_chunk);

            documents_manager.document.active_changed.connect (select_chunk);
        }

        construct {
            get_style_context ().add_class ("documents-notebook");

            settings = Services.AppSettings.get_instance ();
            on_viewport = !settings.zen;

            settings.change.connect ((key) => {
                if (key == "zen") {
                    on_viewport = !settings.zen;
                }
            });
        }

        ~DocumentsNotebook () {
            documents_manager.document.chunk_added.connect (add_chunk);

            documents_manager.document.chunk_removed.connect (remove_chunk);

            documents_manager.document.active_changed.connect (select_chunk);
        }

        public void add_chunk (Models.DocumentChunk chunk, bool active = true) {
            DocumentTab new_tab = new DocumentTab (chunk);
            insert_tab (new_tab, 0);
            if (active) {
                current = new_tab;
            }
        }

        public void remove_chunk (Models.DocumentChunk chunk) {
            for (int i = 0; i < tabs.length (); i++) {
                DocumentTab t = (DocumentTab) tabs.nth (i);
                if (t.chunk == chunk) {
                    remove_tab (t);
                    return;
                }
            }
        }

        public void select_chunk (Models.DocumentChunk chunk) {
            for (int i = 0; i < tabs.length (); i++) {
                DocumentTab t = (DocumentTab) tabs.nth (i);
                if (t.chunk != null && t.chunk == chunk) {
                    current = t;
                    documents_manager.document.set_active (chunk);
                    return;
                }
            }
        }
    }
}
