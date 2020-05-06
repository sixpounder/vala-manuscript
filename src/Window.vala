namespace Manuscript {
    public class Window : Gtk.ApplicationWindow {
        protected uint configure_id = 0;
        protected Services.AppSettings settings;
        protected Gtk.Stack container;
        protected Widgets.Sidebar sidebar;
        protected Gtk.Box layout;
        protected WelcomeView welcome_view;
        protected Header header;
        protected StatusBar status_bar;
        protected SearchBar search_bar;
        protected Gtk.Bin body;
        protected Gtk.Paned editor_grid;
        protected Widgets.EditorsController tabs;
        protected weak Models.Document selected_document = null;

        public Services.DocumentManager document_manager;
        public Services.ActionManager action_manager { get; private set; }
        public string initial_document_path { get; construct; }

        public Editor ? current_editor {
            get {
                if (tabs.tabs.length () != 0) {
                    return ((Widgets.EditorPage) tabs.current_tab.page).editor;
                } else {
                    return null;
                }
            }
        }

        public Models.Document? document {
            get {
                if (document_manager != null && document_manager.has_document) {
                    return document_manager.document;
                } else {
                    return null;
                }
            }

            set {
                document_manager.set_current_document (value);
            }
        }

        public Window.with_document (Manuscript.Application app, string ? document_path = null) {
            Object (
                application: app,
                initial_document_path: document_path
            );

            settings = Services.AppSettings.get_default ();
            action_manager = new Services.ActionManager ((Manuscript.Application) application, this);
            document_manager = new Services.DocumentManager ((Manuscript.Application) application, this);

            // Load some styles
            var css_provider = new Gtk.CssProvider ();
            css_provider.load_from_resource (Manuscript.Constants.MAIN_CSS_URI);
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
            sidebar = new Widgets.Sidebar (this);
            sidebar.width_request = 250;

            // Setup header
            header = new Header (this);
            set_titlebar (header);

            // Tabs
            tabs = new Widgets.EditorsController (this);

            // Grid
            editor_grid = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            editor_grid.get_style_context ().add_class ("editor_grid");
            editor_grid.valign = Gtk.Align.FILL;
            editor_grid.pack1 (sidebar, false, true);
            editor_grid.pack2 (tabs, true, false);

            // Setup welcome view
            welcome_view = new WelcomeView ();

            body = new Gtk.EventBox ();
            body.vexpand = true;
            body.hexpand = true;
            layout.pack_start (body);

            // Status bar (bottom)
            layout.pack_end (status_bar = new StatusBar (), false, false, 0);

            container.add (layout);

            connect_events ();

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

            //  header.new_file.connect ( () => {
            //      document_manager.document.add_chunk (new Models.DocumentChunk.empty (Models.ChunkType.CHAPTER));
            //  } );

            header.open_file.connect ( () => {
                if (document != null && document.has_changes) {
                    if (quit_dialog () ) {
                        open_file_dialog ();
                    }
                } else {
                    open_file_dialog ();
                }
            } );

            header.save_file.connect ((choose_path) => {
                if (choose_path) {
                    var dialog = new FileSaveDialog (this, document);
                    int res = dialog.run ();
                    if (res == Gtk.ResponseType.ACCEPT) {
                        document.save (dialog.get_filename () );
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
            } );
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
                _ ("Open document"),
                (Gtk.Window)get_toplevel (),
                Gtk.FileChooserAction.OPEN,
                _ ("Cancel"),
                Gtk.ResponseType.CANCEL,
                _ ("Open"),
                Gtk.ResponseType.ACCEPT
            );

            dialog.select_multiple = false;
            dialog.do_overwrite_confirmation = false;

            Gtk.FileFilter file_filter = new Gtk.FileFilter ();
            file_filter.set_filter_name (_("Manuscripts") + " (*.manuscript)");

            foreach (string ext in settings.supported_extensions) {
                file_filter.add_pattern (ext);
            }
            dialog.add_filter (file_filter);

            Gtk.FileFilter all_files = new Gtk.FileFilter ();
            all_files.set_filter_name (_("All files"));
            foreach (string mime in settings.supported_mime_types) {
                all_files.add_mime_type (mime);
            }
            all_files.add_pattern ("*.*");
            dialog.add_filter (all_files);

            var res = dialog.run ();

            if (res == Gtk.ResponseType.ACCEPT) {
                open_file_at_path (dialog.get_filename ());
            }

            dialog.destroy ();
        }

        // Like open_file_at_path, but with a temporary file
        public void open_with_temp_file () {
            try {
                File tmp_file = FileUtils.new_temp_file ();
                open_file_at_path (tmp_file.get_path (), true);
            } catch (GLib.Error err) {
                message (_ ("Unable to create temporary document") );
                error (err.message);
            }
        }

        // Opens file at path and sets up the editor
        public void open_file_at_path (string path, bool temporary = false) requires (path != null) {
            try {
                document_manager.set_current_document (new Models.Document.from_file (path));
                set_layout_body (editor_grid);
            } catch (GLib.Error error) {
                var invalid_file_dialog = new InvalidFileDialog (this);
                invalid_file_dialog.run ();
                invalid_file_dialog.destroy ();
                settings.last_opened_document = "";
            }
        }

        public void show_document_settings () {
            var document_settings_dialog = new Dialogs.GenericDialog (this, new Widgets.DocumentSettings (this));
            document_settings_dialog.destroy_with_parent = true;
            document_settings_dialog.modal = false;
            document_settings_dialog.close.connect (() => { document_settings_dialog.destroy (); });
            document_settings_dialog.response.connect (() => { document_settings_dialog.destroy (); });
            document_settings_dialog.run ();
        }

        protected void set_layout_body (Gtk.Widget widget) {
            if (body.get_child () != null) {
                body.remove (body.get_child () );
            }
            body.add (widget);
            widget.show_all ();
            widget.focus (Gtk.DirectionType.UP);
        }

        protected void close_document (Models.Document document) {
            document_manager.set_current_document (null);
        }

        protected bool on_destroy () {
            return false;
        }

        protected void message (string message, Gtk.MessageType level = Gtk.MessageType.ERROR) {
            var messagedialog = new Gtk.MessageDialog (
                this,
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.ERROR,
                Gtk.ButtonsType.OK,
                message
            );
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
