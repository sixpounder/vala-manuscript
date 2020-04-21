namespace Manuscript {
    public class Window : Gtk.ApplicationWindow {
        protected uint configure_id = 0;
        protected AppSettings settings;
        protected Gtk.Stack container;
        protected Sidebar sidebar;
        protected Gtk.Box layout;
        protected WelcomeView welcome_view;
        protected Header header;
        protected StatusBar status_bar;
        protected SearchBar search_bar;
        protected Gtk.Bin body;
        protected DocumentsNotebook tabs;
        protected Services.DocumentManager document_manager;
        protected weak Document selected_document = null;

        public string initial_document_path { get; construct; }

        public Editor? current_editor {
            get {
                if (tabs.tabs.length () != 0) {
                    return ((EditorPage) tabs.current.page).editor;
                } else {
                    return null;
                }
            }
        }

        public Document document {
            get {
                return selected_document;
            }

            set {
                Document found = null;
                var documents = document_manager.documents;
                for (int i = 0; i < documents.length; i++) {
                    if (documents[i] == value) {
                        found = documents[i];
                        break;
                    }
                }
                if (found != null) {
                    selected_document = found;
                } else {
                    document_manager.add_document (value);
                    selected_document = value;
                }
            }
        }

        public Window.with_document (Gtk.Application app, string? document_path = null) {
            Object (
                application: app,
                initial_document_path: document_path
            );

            settings = AppSettings.get_instance ();
            document_manager = Services.DocumentManager.get_default ();

            // Load some styles
            var css_provider = new Gtk.CssProvider ();
            css_provider.load_from_resource ("/com/github/sixpounder/manuscript/main.css");
            Gtk.StyleContext.add_provider_for_screen (screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            // Position and resize window according to last settings
            int x = settings.window_x;
            int y = settings.window_y;
            if (settings.window_width != -1 || settings.window_height != -1) {
                var rect = Gtk.Allocation ();
                rect.height = settings.window_height;
                rect.width = settings.window_width;
                resize (rect.width, rect.height);
            }

            if (x != -1 && y != -1) {
                move (x, y);
            }

            // Main layout containers
            container = new Gtk.Stack ();
            container.homogeneous = true;
            container.transition_type = Gtk.StackTransitionType.OVER_LEFT;
            add (container);

            layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            // Sidebar
            sidebar = new Sidebar ();
            sidebar.set_stack (container);

            // Setup header
            header = new Header (this);
            set_titlebar (header);

            // Tabs
            tabs = new DocumentsNotebook ();

            // Setup welcome view
            welcome_view = new WelcomeView ();

            layout.pack_start (body = new Gtk.EventBox ());

            // Status bar (bottom)
            layout.pack_end (status_bar = new StatusBar (), false, false, 0);

            container.add (layout);

            connect_events ();
            configure_key_events ();

            container.show_all ();

            // Lift off
            if (initial_document_path != null && initial_document_path != "") {
                open_file_at_path (initial_document_path);
            } else {
                set_layout_body (welcome_view);
            }
        }

        public void connect_events () {
            delete_event.connect (on_destroy);

            header.new_file.connect (() => {
                document_manager.add_document (Document.empty ());
            });

            header.open_file.connect (() => {
                if (this.document != null && document.has_changes) {
                    if (quit_dialog ()) {
                        open_file_dialog ();
                    }
                } else {
                    open_file_dialog ();
                }
            });

            header.save_file.connect ((choose_path) => {
                if (choose_path) {
                    var dialog = new FileSaveDialog (this, document);
                    int res = dialog.run ();
                    if (res == Gtk.ResponseType.ACCEPT) {
                        document.save (dialog.get_filename ());
                        settings.last_opened_document = this.document.file_path;
                    }
                    dialog.destroy ();
                } else {
                    document.save ();
                }
            });

            welcome_view.should_open_file.connect (open_file_dialog);
            welcome_view.should_create_new_file.connect (open_with_temp_file);
        }

        public void configure_searchbar () {
            search_bar = new SearchBar (this, current_editor);
            layout.pack_start (search_bar, false, false, 0);
            settings.change.connect ((k) => {
                if (k == "searchbar") {
                    show_searchbar ();
                }
            });
        }

        public bool configure_key_events () {
            key_press_event.connect ((e) => {
                uint keycode = e.hardware_keycode;

                if ((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                    if (Manuscript.Utils.Keys.match_keycode (Gdk.Key.f, keycode)) {
                        if (settings.searchbar == false) {
                            debug ("Searchbar on");
                            settings.searchbar = true;
                        } else {
                            debug ("Searchbar off");
                            settings.searchbar = false;
                        }
                    } else if (Manuscript.Utils.Keys.match_keycode (Gdk.Key.s, keycode)) {
                        if (document.temporary) {
                            // Ask where to save this
                            var dialog = new FileSaveDialog (this, document);
                            int res = dialog.run ();
                            if (res == Gtk.ResponseType.ACCEPT) {
                                document.save (dialog.get_filename ());
                            }
                            dialog.destroy ();
                        } else {
                            document.save ();
                        }
                    }
                }

                return false;
            });

            return false;
        }

        public override bool configure_event (Gdk.EventConfigure event) {
            if (configure_id != 0) {
                GLib.Source.remove (configure_id);
            }

            // Avoid trashing the disc
            configure_id = Timeout.add (100, () => {
                configure_id = 0;

                int height, width;
                this.get_size (out width, out height);
                settings.window_width = width;
                settings.window_height = height;

                int root_x, root_y;
                this.get_position (out root_x, out root_y);
                settings.window_x = root_x;
                settings.window_y = root_y;

                return false;
            });

            return base.configure_event (event);
        }

        public void show_searchbar () {
            search_bar.rebind (current_editor);
            search_bar.reveal_child = settings.searchbar;
            if (settings.searchbar == true) {
                search_bar.search_entry.grab_focus_without_selecting ();
            }
        }

        /**
         * Shows the open document dialog
         */
        public void open_file_dialog () {
            Gtk.FileChooserDialog dialog = new Gtk.FileChooserDialog (
                _("Open document"),
                (Gtk.Window) get_toplevel (),
                Gtk.FileChooserAction.OPEN,
                _("Cancel"),
                Gtk.ResponseType.CANCEL,
                _("Open"),
                Gtk.ResponseType.ACCEPT
            );

            Gtk.FileFilter text_file_filter = new Gtk.FileFilter ();
            text_file_filter.add_mime_type ("text/plain");
            text_file_filter.add_mime_type ("text/markdown");
            text_file_filter.add_pattern ("*.txt");
            text_file_filter.add_pattern ("*.md");
            text_file_filter.add_pattern ("*.manuscript");

            dialog.add_filter (text_file_filter);

            dialog.response.connect ((res) => {
                dialog.hide ();
                if (res == Gtk.ResponseType.ACCEPT) {
                    open_file_at_path (dialog.get_filename ());
                }
            });

            dialog.run ();
        }

        // Like open_file_at_path, but with a temporary file
        public void open_with_temp_file () {
            try {
                File tmp_file = FileUtils.new_temp_file ();
                open_file_at_path (tmp_file.get_path (), true);
            } catch (GLib.Error err) {
                message (_("Unable to create temporary document"));
                error (err.message);
            }
        }

        // Opens file at path and sets up the editor
        public void open_file_at_path (string path, bool temporary = false) {
            // tabs.add_document (Document.from_file (path));
            document_manager.add_document (Document.from_file (path));
            set_layout_body (tabs);
        }

        protected void set_layout_body (Gtk.Widget widget) {
            if (body.get_child () != null) {
                body.remove (body.get_child ());
            }
            body.add (widget);
            widget.show_all ();
            widget.focus (Gtk.DirectionType.UP);
        }

        protected void close_document (Document document) {
            var documents = document_manager.documents;
            for (int i = 0; i < documents.length; i++) {
                if (document == documents[i]) {
                    document_manager.remove_document(document);
                    break;
                }
            }
        }

        protected bool on_destroy () {
            return false;
        }

        protected void message (string message, Gtk.MessageType level = Gtk.MessageType.ERROR) {
            var messagedialog = new Gtk.MessageDialog (this,
                                    Gtk.DialogFlags.MODAL,
                                    Gtk.MessageType.ERROR,
                                    Gtk.ButtonsType.OK,
                                    message);
            messagedialog.show ();
        }

        protected bool quit_dialog () {
            QuitDialog confirm_dialog = new QuitDialog (this);

            int outcome = confirm_dialog.run ();
            confirm_dialog.destroy ();

            return outcome == 1;
        }

        protected void show_not_found_alert () {
            FileNotFound fnf = new FileNotFound (document.file_path);
            set_layout_body (fnf);
        }
    }
}

