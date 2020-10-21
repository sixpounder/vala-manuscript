namespace Manuscript {
    public class Window : Gtk.ApplicationWindow {
        protected uint configure_id = 0;
        protected Services.AppSettings settings;
        protected Gtk.Stack container;
        protected Widgets.Sidebar sidebar;
        protected Gtk.Box layout;
        protected WelcomeView welcome_view;
        protected Widgets.Header header;
        protected Gtk.Bin body;
        protected Gtk.Paned editor_grid;
        protected Widgets.EditorsController tabs;
        protected weak Models.Document selected_document = null;
        protected Gtk.InfoBar infobar;
        protected int last_editor_grid_panel_position;
        public Widgets.SearchPanel search_panel { get; private set; }

        public Services.DocumentManager document_manager;
        public Services.ActionManager action_manager { get; private set; }
        public string initial_document_path { get; construct; }
        public string cache_folder { get; construct; }

        public Models.Document ? document {
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

        public weak Protocols.EditorController current_editor {
            get {
                return tabs.get_current_editor ();
            }
        }

        public Window.with_document (Manuscript.Application app, string ? document_path = null) {
            Object (
                application: app,
                initial_document_path: document_path,
                cache_folder: Path.build_path(Path.DIR_SEPARATOR_S, Environment.get_user_cache_dir (), Constants.APP_ID)
            );

            settings = Services.AppSettings.get_default ();
            action_manager = new Services.ActionManager ((Manuscript.Application)application, this);
            document_manager = new Services.DocumentManager ((Manuscript.Application)application, this);

            // Connect document manager events
            document_manager.load.connect (() => {
                set_layout_body (editor_grid);
            });

            document_manager.unloaded.connect (() => {
                set_layout_body (welcome_view);
            });

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

            // Search panel
            search_panel = new Widgets.SearchPanel (this);

            // Sidebar
            sidebar = new Widgets.Sidebar (this);
            sidebar.width_request = 250;

            // Setup header
            header = new Widgets.Header (this);
            set_titlebar (header);

            // right panel layout (search + tabs)
            var right_panel = new Gtk.Box (Gtk.Align.VERTICAL, 0);
            tabs = new Widgets.EditorsController (this);
            right_panel.pack_start (search_panel, false, false, 0);
            right_panel.pack_start (tabs);

            // Grid
            editor_grid = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            editor_grid.get_style_context ().add_class ("editor_grid");
            editor_grid.valign = Gtk.Align.FILL;
            editor_grid.pack1 (sidebar, false, true);
            editor_grid.pack2 (right_panel, true, false);

            // Setup welcome view
            welcome_view = new WelcomeView ();

            // A convenience wrapper to switch between welcome view and editor view
            body = new Gtk.EventBox ();
            body.expand = true;

            // This is used to eventually pack an infobar at the top.
            // Otherwise it just contains the body
            layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            layout.homogeneous = false;
            layout.pack_start (body);

            connect_events ();

            container.add (layout);
            container.show_all ();

            // Lift off
            if (initial_document_path != null && initial_document_path != "") {
                open_file_at_path (initial_document_path);
            } else {
                set_layout_body (welcome_view);
            }
            editor_grid.position = 300;
            update_ui ();
        }

        public void connect_events () {
            settings.change.connect (update_ui);
            delete_event.connect (on_destroy);
            welcome_view.should_open_file.connect (open_file_dialog);
            welcome_view.should_create_new_file.connect (open_with_temp_file);
        }

        public void update_ui () {
            if (settings.zen) {
                last_editor_grid_panel_position = editor_grid.position;
                editor_grid.position = 0;
            } else {
                if (editor_grid.position == 0 && last_editor_grid_panel_position != 0) {
                    editor_grid.position = last_editor_grid_panel_position;
                }

                search_panel.reveal_child = settings.searchbar;
                search_panel.search_entry.grab_focus_without_selecting ();

                if (settings.searchbar == false) {
                    search_panel.unselect ();
                }
            }
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
            file_filter.set_filter_name (_ ("Manuscripts") + " (*.manuscript)");

            foreach (string ext in settings.supported_extensions) {
                file_filter.add_pattern (ext);
            }
            dialog.add_filter (file_filter);

            Gtk.FileFilter all_files = new Gtk.FileFilter ();
            all_files.set_filter_name (_ ("All files"));
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
                File tmp_file = FileUtils.new_temp_file (
                    new Manuscript.Models.Document.empty ().to_json ()
                );
                open_file_at_path (tmp_file.get_path (), true);
            } catch (GLib.Error err) {
                message (_ ("Unable to create temporary document") );
                error (err.message);
            }
        }

        // Opens file at path and sets up the editor
        public void open_file_at_path (string path, bool temporary = false)
        requires (path != null) {
            try {
                hide_infobar ();
                document_manager.set_current_document (
                    new Models.Document.from_file (path)
                );
            } catch (GLib.Error error) {
                warning (error.message);
                string msg;
                if (error is Models.DocumentError.NOT_FOUND) {
                    msg = _("File at %s could not be found. It may have been moved or deleted.");
                    if (settings.last_opened_document == path) {
                        set_layout_body (welcome_view);
                    }
                } else if (error is Models.DocumentError.READ) {
                    msg = "<b>%s</b><br><span>%s</span>"
                        .printf(
                            _("Cannot read %s").printf(path),
                            _("The file you selected does not appear to be a valid Manuscript file")
                        );
                } else {
                    msg = _("Some strange error happened while trying to open file at %s").printf(path);
                }

                var infobar_instance = show_infobar (Gtk.MessageType.WARNING, msg.printf (@"<b>$path</b>"));
                infobar_instance.add_button (_ ("Dismiss"), Gtk.ResponseType.CLOSE);
                infobar_instance.response.connect ((res) => {
                    switch (res) {
                    case Gtk.ResponseType.CLOSE:
                        infobar_instance.destroy ();
                        break;
                    default:
                        assert_not_reached ();
                    }
                });
            }
        }

        public void show_document_settings () {
            var document_settings_dialog = new Dialogs.GenericDialog (this, new Widgets.DocumentSettings (this));
            document_settings_dialog.destroy_with_parent = true;
            document_settings_dialog.modal = false;
            document_settings_dialog.close.connect (() => {
                if (!document_manager.document.temporary) {
                    document_manager.document.save ();
                }
                document_settings_dialog.destroy ();
            });
            document_settings_dialog.response.connect (() => {
                if (!document_manager.document.is_temporary ()) {
                    document_manager.document.save ();
                }
                document_settings_dialog.destroy ();
            });
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

        protected Gtk.InfoBar show_infobar (Gtk.MessageType level, string message) {
            var label = new Gtk.Label (message);
            label.lines = 2;
            label.wrap = true;
            label.use_markup = true;

            hide_infobar ();
            infobar = new Gtk.InfoBar ();
            infobar.message_type = level;
            infobar.show_close_button = false;
            infobar.revealed = true;
            infobar.get_content_area ().add (label);
            infobar.show_all ();

            layout.pack_start (infobar, false, true);
            layout.reorder_child (infobar, 0);
            return infobar;
        }

        protected void hide_infobar () {
            if (infobar != null) {
                infobar.destroy ();
                infobar.unref ();
            }
        }
    }
}
