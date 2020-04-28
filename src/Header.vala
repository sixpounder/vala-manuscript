namespace Manuscript {
    public class Header : Gtk.HeaderBar {
        public weak Gtk.Window parent_window { get; construct; }

        public signal void new_file ();
        public signal void open_file ();
        public signal void save_file (bool choose_path);

        protected Gtk.Switch zen_switch;
        protected Gtk.Button settings_button;
        //  protected Gtk.Button save_file_button;
        //  protected Gtk.Button save_file_as_button;
        protected Widgets.MenuButton export_button;
        protected Widgets.SettingsPopover settings_popover;
        protected Widgets.ExportPopover export_popover;
        protected Services.DocumentManager document_manager;
        protected Services.AppSettings settings;

        public weak Models.Document document {
            get {
                return document_manager.document;
            }
        }

        protected bool has_changes {
            get {
                return document != null && document.has_changes;
            }
        }

        public Header (Gtk.Window parent) {
            Object (
                title: Constants.APP_NAME,
                parent_window: parent,
                has_subtitle: true,
                show_close_button: true,
                spacing: 10
            );

            document_manager = Services.DocumentManager.get_default ();
            settings = Services.AppSettings.get_default ();

            Widgets.MenuButton menu_button = new Widgets.MenuButton.with_properties ("folder", "Menu");
            menu_button.menu_model = Menus.get_default ().main_menu;
            pack_start (menu_button);

            Widgets.MenuButton add_chunk_button = new Widgets.MenuButton.with_properties ("insert-object", "Insert");
            add_chunk_button.menu_model = Menus.get_default ().create_menu;
            pack_start (add_chunk_button);

            export_button = new Widgets.MenuButton.with_properties ("document-export", "Export");
            export_button.activated.connect (() => {
                if (export_popover.visible) {
                    export_popover.popdown ();
                } else {
                    export_popover.popup ();
                    export_popover.show_all ();
                }
            });
            pack_start (export_button);
            export_popover = new Widgets.ExportPopover (export_button);

            //  Gtk.Button new_file_button = new Gtk.Button.from_icon_name ("document-new", Gtk.IconSize.LARGE_TOOLBAR);
            //  new_file_button.tooltip_text = _ ("New file");
            //  new_file_button.clicked.connect (() => {
            //      new_file ();
            //  });
            //  pack_start (new_file_button);

            //  Gtk.Button open_file_button = new Gtk.Button.from_icon_name ("document-open", Gtk.IconSize.LARGE_TOOLBAR);
            //  open_file_button.tooltip_text = _ ("Open file");
            //  open_file_button.clicked.connect (() => {
            //      open_file ();
            //  });
            //  pack_start (open_file_button);

            //  save_file_button = new Gtk.Button.from_icon_name ("document-save", Gtk.IconSize.LARGE_TOOLBAR);
            //  save_file_button.tooltip_text = _ ("Save file");
            //  save_file_button.clicked.connect (() => {
            //      save_file (false);
            //  });
            //  save_file_button.sensitive = document != null ? has_changes : false;
            //  pack_start (save_file_button);

            //  save_file_as_button = new Gtk.Button.from_icon_name ("document-save-as", Gtk.IconSize.LARGE_TOOLBAR);
            //  save_file_as_button.tooltip_text = _ ("Save file as");
            //  save_file_as_button.clicked.connect (() => {
            //      save_file (true);
            //  });
            //  save_file_button.sensitive = document != null ? has_changes : false;
            //  pack_start (save_file_as_button);

            update_icons ();

            settings_button = new Gtk.Button.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
            settings_button.tooltip_text = _ ("Settings");
            settings_button.clicked.connect (() => {
                if (settings_popover.visible) {
                    settings_popover.popdown ();
                } else {
                    settings_popover.popup ();
                    settings_popover.show_all ();
                }
            });
            pack_end (settings_button);
            settings_popover = new Widgets.SettingsPopover (settings_button);

            zen_switch = new Gtk.Switch ();
            zen_switch.set_vexpand (false);
            zen_switch.set_hexpand (false);
            zen_switch.halign = Gtk.Align.CENTER;
            zen_switch.valign = Gtk.Align.CENTER;
            zen_switch.active = settings.zen;
            zen_switch.state_set.connect (() => {
                update_settings ();
                return false;
            });
            pack_end (zen_switch);

            update_ui ();

            settings.change.connect (update_ui);

            document_manager.load.connect (update_ui);
            document_manager.change.connect (update_ui);
        }

        ~ Header () {
            settings.change.disconnect (update_ui);
            document_manager.load.disconnect (update_ui);
            document_manager.change.disconnect (update_ui);
        }

        protected void update_subtitle () {
            subtitle = document.filename + (has_changes ? " (" + _ ("modified") + ")" : "");
        }

        protected void update_icons () {
            //  save_file_button.sensitive = has_changes;
            //  save_file_as_button.sensitive = has_changes;
        }

        protected void update_ui () {
            zen_switch.sensitive = document != null;
            export_button.sensitive = document != null;
            zen_switch.active = settings.zen;
        }

        protected void on_document_change () {
            update_subtitle ();
            update_icons ();
        }

        protected void on_document_saved (string to_path) {
            update_subtitle ();
            update_icons ();
        }

        protected void update_settings () {
            settings.zen = zen_switch.active;
        }

        protected void load_document () {
            //  document.change.connect (on_document_change);
            document.saved.connect (on_document_saved);
            //  document.undo.connect (on_document_change);
            //  document.redo.connect (on_document_change);
            update_subtitle ();
            update_icons ();
        }
    }
}
