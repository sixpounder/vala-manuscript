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

namespace Manuscript {
    public class Window : Gtk.ApplicationWindow {
        public signal void search_result (Gtk.TextBuffer buffer, Gtk.TextIter result_start);

        private uint configure_id = 0;
        private Services.AppSettings settings;
        private Gtk.Overlay container;
        private Widgets.Sidebar sidebar;
        private Gtk.Box layout;
        private Widgets.WelcomeView welcome_view;
        private Widgets.Header header;
        private Gtk.Bin body;
        private Gtk.Paned editor_grid;
        private Gtk.InfoBar infobar;
        private Manuscript.Widgets.QuickOpenPanel quick_open_panel;
        private int last_editor_grid_panel_position = 0;
        private Widgets.EditorsController editors_controller;
        public Widgets.SearchPanel search_panel { get; private set; }

        public Services.DocumentManager document_manager;
        public Services.ActionManager action_manager { get; private set; }
        public string initial_document_path { get; construct; }
        public string cache_folder { get; construct; }

        public Protocols.ChunkEditor? current_editor {
            get {
                return editors_controller.current_editor;
            }
        }

        public Models.Document ? document {
            get {
                if (document_manager != null && document_manager.has_document) {
                    return document_manager.document;
                } else {
                    return null;
                }
            }
        }

        public Window.with_document (Manuscript.Application app, string ? document_path = null) {
            Object (
                application: app,
                initial_document_path: document_path,
                cache_folder: Path.build_path (
                    Path.DIR_SEPARATOR_S, Environment.get_user_cache_dir (), Constants.APP_ID
                )
            );

            settings = Services.AppSettings.get_default ();
            action_manager = new Services.ActionManager ((Manuscript.Application)application, this);
            document_manager = new Services.DocumentManager ((Manuscript.Application)application, this);

            // In case the theme has never been set, rely on gtk.settings
            if (settings.theme == "System") {
                settings.prefer_dark_style = Gtk.Settings.get_default ().gtk_application_prefer_dark_theme;
                settings.theme = settings.prefer_dark_style ? "Dark" : "Light";
            } else {
                settings.prefer_dark_style = settings.theme == "Dark";
            }

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

            // Quick open panel
            quick_open_panel = new Manuscript.Widgets.QuickOpenPanel (document_manager);
            quick_open_panel.no_show_all = true;
            quick_open_panel.hide ();

            // Main layout containers
            container = new Gtk.Overlay ();
            add (container);

            // Search panel
            search_panel = new Widgets.SearchPanel (this);

            // Sidebar
            sidebar = new Widgets.Sidebar (this);
            sidebar.width_request = 250;

            // Setup header
            header = new Widgets.Header (this);
            if (get_realized () == false) {
                set_titlebar (header);
            }

            // right panel layout (search + tabs)
            var right_panel = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            editors_controller = new Widgets.EditorsController (this);
#if GTK_4
            right_panel.append (search_panel);
            right_panel.append (editors_controller);
#else
            right_panel.pack_start (search_panel, false, false, 0);
            right_panel.pack_start (editors_controller);
#endif

            // Grid
            editor_grid = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
            editor_grid.get_style_context ().add_class ("editor_grid");
            editor_grid.valign = Gtk.Align.FILL;
            editor_grid.pack1 (sidebar, false, true);
            editor_grid.pack2 (right_panel, true, false);
            editor_grid.position = Mathz.max (250, last_editor_grid_panel_position);

            // Setup welcome view
            welcome_view = new Widgets.WelcomeView ();

            // A convenience wrapper to switch between welcome view and editor view
            body = new Gtk.EventBox ();
            body.expand = true;

            // This is used to eventually pack an infobar at the top.
            // Otherwise it just contains the body
            layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            layout.homogeneous = false;
#if GTK_4
            layout.append (body);
#else
            layout.pack_start (body);
#endif

            connect_events ();

            container.add (layout);
            container.add_overlay (quick_open_panel);
            container.show_all ();

            // Lift off
            if (initial_document_path != null && initial_document_path != "") {
                open_file_at_path.begin (initial_document_path);
            } else {
                set_layout_body (welcome_view);
            }

            update_ui ();
        }

        public void connect_events () {
            settings.change.connect (update_ui);
            welcome_view.should_open_file.connect (open_file_dialog);
            welcome_view.should_create_new_file.connect (open_with_temp_file);

            // Connect document manager events
            document_manager.load.connect (on_document_manager_load);
            document_manager.unloaded.connect (on_document_manager_unload);
            document_manager.backend_file_unlinked.connect (on_backend_file_deleted);
        }

        public void update_ui () {
            if (settings.focus_mode) {
                last_editor_grid_panel_position = editor_grid.position;
                editor_grid.position = 0;
            } else {
                editor_grid.position = last_editor_grid_panel_position < 250 ? 250 : last_editor_grid_panel_position;

                search_panel.reveal_child = settings.searchbar;
                if (search_panel.search_entry != null && search_panel.reveal_child) {
                    search_panel.search_entry.grab_focus_without_selecting ();
                }

                if (settings.searchbar == false) {
                    search_panel.unselect ();
                }
            }
        }

        public override void destroy () {
            settings.change.disconnect (update_ui);
            welcome_view.should_open_file.disconnect (open_file_dialog);
            welcome_view.should_create_new_file.disconnect (open_with_temp_file);
            search_panel.result.connect (on_search_result);

            // Connect document manager events
            document_manager.load.disconnect (on_document_manager_load);
            document_manager.unloaded.disconnect (on_document_manager_unload);
            document_manager.backend_file_unlinked.disconnect (on_backend_file_deleted);

            base.destroy ();
        }

        public override bool delete_event (Gdk.EventAny event) {
            if (!document_manager.has_document) {
                settings.last_opened_document = "";
            } else {
                settings.last_opened_document = document_manager.document.file_path;
            }

            if (settings.autosave) {
                if (document_manager.has_document) {
                    document_manager.close.begin ((obj, res) => {
                        try {
                            document_manager.close.end (res);
                        } catch (Models.DocumentError e) {
                            critical (e.message);
                            show_infobar (Gtk.MessageType.ERROR, @"$(_("Could not save this file")): $(e.message)");
                        }
                    });
                }
                return false;
            } else {
                if (document_manager.has_document && document_manager.document.has_changes) {
                    return !quit_dialog ();
                } else {
                    return false;
                }
            }
        }

        public override bool configure_event (Gdk.EventConfigure event) {
            if (configure_id != 0) {
                GLib.Source.remove (configure_id);
            }

            // Avoid trashing the disk
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

        protected void on_search_result (Gtk.TextBuffer buffer, Gtk.TextIter result_start) {
            // Broadcast the event for editors to listen
            search_result (buffer, result_start);
        }

        protected void on_backend_file_deleted () {
            var infobar_instance = show_infobar (
                Gtk.MessageType.WARNING,
                "The current manuscript file has been deleted or moved. Do you want to save it again?"
            );
            infobar_instance.add_button (_ ("Save"), Gtk.ResponseType.YES);
            infobar_instance.add_button (_ ("Dismiss"), Gtk.ResponseType.NO);
            infobar_instance.response.connect ((res) => {
                switch (res) {
                case Gtk.ResponseType.NO:
                    break;
                case Gtk.ResponseType.YES:
                    document_manager.save.begin (true);
                    break;
                default:
                    assert_not_reached ();
                }

                infobar_instance.destroy ();
            });
        }

        protected void on_document_manager_load () {
            set_layout_body (editor_grid);
        }

        protected void on_document_manager_unload () {
            set_layout_body (welcome_view);
        }

        /**
         * Shows the open document dialog
         */
        public void open_file_dialog () {
            Gtk.FileChooserDialog dialog = new Gtk.FileChooserDialog (
                _ ("Open document"),
                this,
                Gtk.FileChooserAction.OPEN,
                _ ("Cancel"),
                Gtk.ResponseType.CANCEL,
                _ ("Open"),
                Gtk.ResponseType.ACCEPT
            );

            dialog.select_multiple = false;
            dialog.do_overwrite_confirmation = false;

            Gtk.FileFilter file_filter = new Gtk.FileFilter ();
            file_filter.set_filter_name (_ ("Manuscripts"));

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
                open_file_at_path.begin (dialog.get_filename ());
            }

            dialog.destroy ();
        }

        // Like open_file_at_path, but with a temporary file
        public void open_with_temp_file () {
            try {
                var new_tmp_document = new Manuscript.Models.Document.empty ();
                var tmp_file_path = Path.build_filename (
                    Environment.get_user_cache_dir (),
                    Constants.APP_ID,
                    @"$(GLib.Uuid.string_random ())$(Constants.DEFAULT_FILE_EXT)"
                );
                new_tmp_document.save (tmp_file_path);
                open_file_at_path.begin (tmp_file_path, true);
            } catch (GLib.Error err) {
                message (_ ("Unable to create temporary document") );
                error (err.message);
            }
        }

        // Opens file at path and sets up the editor
        public async void open_file_at_path (string path, bool temporary = false)
        requires (path != null) {
            try {
                hide_infobar ();
                yield document_manager.load_from_path (path);
            } catch (Models.DocumentError error) {
                warning (error.message);
                string msg;
                if (error is Models.DocumentError.NOT_FOUND) {
                    msg = _ ("File at %s could not be found. It may have been moved or deleted.");
                    if (settings.last_opened_document == path) {
                        set_layout_body (welcome_view);
                    }
                } else if (error is Models.DocumentError.READ) {
                    msg = "<b>%s</b> - <span>%s</span>"
                        .printf (
                            _ ("Cannot read %s").printf (path),
                            _ ("The file you selected does not appear to be readable")
                        );
                } else if (error is Models.DocumentError.PARSE) {
                    msg = "<b>%s</b> - <span>%s</span>"
                        .printf (
                            _ ("Cannot parse %s").printf (path),
                            _ ("The file you selected does not appear to be a valid Manuscript file")
                        );
                } else {
                    msg = _ ("Some strange error happened while trying to open file at %s").printf (path);
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

                try {
                    yield document_manager.close ();
                } catch (Models.DocumentError e) {
                    critical (e.message);
                }
            }
        }

        public void show_quick_open_panel () {
            if (quick_open_panel.visible) {
                quick_open_panel.hide ();
            } else {
                quick_open_panel.show ();
            }
        }

        public void show_document_settings () {
            var document_settings_dialog = new Dialogs.GenericDialog (this, new Widgets.DocumentSettings (this));
            document_settings_dialog.title = _("Document properties");
            document_settings_dialog.destroy_with_parent = true;
            document_settings_dialog.modal = false;
            document_settings_dialog.close.connect (() => {
                document_settings_dialog.destroy ();
            });
            document_settings_dialog.response.connect (() => {
                document_settings_dialog.destroy ();
            });
            document_settings_dialog.run ();
        }

        private void set_layout_body (Gtk.Widget widget) {
            if (body.get_child () != null) {
                body.remove (body.get_child () );
            }
            body.add (widget);
            widget.show_all ();
            widget.focus (Gtk.DirectionType.UP);
        }

        private void message (string message, Gtk.MessageType level = Gtk.MessageType.ERROR) {
            var messagedialog = new Gtk.MessageDialog (
                this,
                Gtk.DialogFlags.MODAL,
                Gtk.MessageType.ERROR,
                Gtk.ButtonsType.OK,
                message
            );
            messagedialog.show ();
        }

        private bool quit_dialog () {
            QuitDialog confirm_dialog = new QuitDialog (this);

            int outcome = confirm_dialog.run ();
            confirm_dialog.destroy ();

            return outcome == 1;
        }

        //  private void show_not_found_alert () {
        //      FileNotFound fnf = new FileNotFound (document.file_path);
        //      set_layout_body (fnf);
        //  }

        private Gtk.InfoBar show_infobar (Gtk.MessageType level, string message) {
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

#if GTK_4
            layout.append (infobar);
#else
            layout.pack_start (infobar, false, true);
#endif
            layout.reorder_child (infobar, 0);
            return infobar;
        }

        private void hide_infobar () {
            if (infobar != null) {
                infobar.destroy ();
            }
        }
    }
}
