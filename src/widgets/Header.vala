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
    public class Header : Gtk.HeaderBar {
        public weak Manuscript.Window parent_window { get; construct; }

        public signal void new_file ();
        public signal void open_file ();
        public signal void save_file (bool choose_path);

        protected Gtk.Switch zen_switch;
        protected Widgets.MenuButton settings_button;
        protected Widgets.MenuButton menu_button;
        protected Widgets.MenuButton add_element_button;
        protected Widgets.MenuButton export_button;
        protected Widgets.MenuButton document_settings_button;

        protected Widgets.SettingsPopover settings_popover;
        protected Widgets.ExportPopover export_popover;
        protected weak Services.DocumentManager document_manager;
        protected Services.AppSettings settings;

        public weak Models.Document document {
            get {
                return document_manager.document;
            }
        }

        protected bool has_changes {
            get {
                return document_manager.has_document && document.has_changes;
            }
        }

        public Header (Manuscript.Window parent) {
            Object (
                title: Constants.APP_NAME,
                parent_window: parent,
                has_subtitle: true,
                show_close_button: true,
                spacing: 15
            );
        }

        construct {
            document_manager = parent_window.document_manager;
            settings = Services.AppSettings.get_default ();
            build_ui ();
        }

        ~ Header () {
            settings.change.disconnect (update_ui);
            document_manager.load.disconnect (update_ui);
            document_manager.unload.disconnect (update_ui);
            //  document_manager.change.disconnect (update_ui);
        }

        /**
         * Builds the UI for this widget
         */
        private void build_ui () {
            menu_button = new Widgets.MenuButton.with_properties ("folder", "Menu");
            menu_button.popover = build_main_menu_popover ();
            menu_button.popover.width_request = 350;
            menu_button.sensitive = document_manager.has_document;
            pack_start (menu_button);

            add_element_button = new Widgets.MenuButton.with_properties ("insert-object", "Insert");
            add_element_button.sensitive = document_manager.has_document;
            add_element_button.popover = build_add_element_menu ();
            pack_start (add_element_button);

            document_settings_button = new Widgets.MenuButton.with_properties (
                "document-properties",
                "Properties",
                @"$(Services.ActionManager.ACTION_PREFIX)$(Services.ActionManager.ACTION_DOCUMENT_SETTINGS)"
            );
            document_settings_button.hint = MenuButtonHint.MODAL;
            document_settings_button.sensitive = document_manager.has_document;
            pack_start (document_settings_button);

            export_button = new Widgets.MenuButton.with_properties (
                "document-export",
                "Export",
                @"$(Services.ActionManager.ACTION_PREFIX)$(Services.ActionManager.ACTION_EXPORT)"
            );
            export_button.hint = MenuButtonHint.MODAL;
            export_button.sensitive = document_manager.has_document;
            pack_start (export_button);

            settings_popover = new Widgets.SettingsPopover (parent_window.application);
            settings_button = new Widgets.MenuButton.with_properties ("open-menu", _("Settings"));
            settings_button.tooltip_text = _ ("Application settings");
            settings_button.popover = settings_popover;
            pack_end (settings_button);

            settings.change.connect (update_ui);
            document_manager.load.connect_after (update_ui);
            document_manager.unloaded.connect_after (update_ui);
            document_manager.property_change.connect (update_ui);

            update_ui ();
        }

        private Gtk.PopoverMenu build_main_menu_popover () {
            var grid = new Gtk.Grid ();
            grid.margin_top = 6;
            grid.margin_bottom = 3;
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.width_request = 240;
            grid.name = "main";

            var new_window_button = create_model_button (
                _("New window"),
                "document-new-symbolic",
                @"$(Services.ActionManager.ACTION_PREFIX)$(Services.ActionManager.ACTION_NEW_WINDOW)"
            );

            var open_button = create_model_button (
                _("Open"),
                "document-open-symbolic",
                @"$(Services.ActionManager.ACTION_PREFIX)$(Services.ActionManager.ACTION_OPEN)"
            );

            var save_button = create_model_button (
                _("Save"),
                "document-save-symbolic",
                @"$(Services.ActionManager.ACTION_PREFIX)$(Services.ActionManager.ACTION_SAVE)"
            );

            var save_as_button = create_model_button (
                _("Save as"),
                "document-save-as-symbolic",
                @"$(Services.ActionManager.ACTION_PREFIX)$(Services.ActionManager.ACTION_SAVE_AS)"
            );

            var document_settings_button = create_model_button (
                _("Document settings"),
                "document-settings-symbolic",
                @"$(Services.ActionManager.ACTION_PREFIX)$(Services.ActionManager.ACTION_DOCUMENT_SETTINGS)"
            );

            var document_close_button = create_model_button (
                _("Close document"),
                "folder-symbolic",
                @"$(Services.ActionManager.ACTION_PREFIX)$(Services.ActionManager.ACTION_CLOSE_DOCUMENT)"
            );

            var quit_button = create_model_button (
                _("Quit"),
                "application-exit-symbolic",
                @"$(Services.ActionManager.ACTION_PREFIX)$(Services.ActionManager.ACTION_QUIT)"
            );

            grid.add (new_window_button);
            grid.add (open_button);
            grid.add (save_button);
            grid.add (save_as_button);
            grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
            grid.add (document_settings_button);
            grid.add (document_close_button);
            grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
            grid.add (quit_button);
            grid.show_all ();

            var popover = new Gtk.PopoverMenu ();
            popover.add (grid);

            return popover;
        }

        private Gtk.PopoverMenu build_add_element_menu () {
            var grid = new Gtk.Grid ();
            grid.margin_top = 6;
            grid.margin_bottom = 3;
            grid.orientation = Gtk.Orientation.VERTICAL;
            grid.width_request = 240;
            grid.name = "main";

#if CHUNK_CHAPTER
            var add_chapter_button = create_model_button (
                _("Chapter"),
                Models.ChunkType.CHAPTER.to_icon_name (),
                @"$(Services.ActionManager.ACTION_PREFIX)$(Services.ActionManager.ACTION_ADD_CHAPTER)"
            );
            grid.add (add_chapter_button);
#endif

#if CHUNK_CHARACTER_SHEET
            var add_character_sheet_button = create_model_button (
                _("Character sheet"),
                Models.ChunkType.CHARACTER_SHEET.to_icon_name (),
                @"$(Services.ActionManager.ACTION_PREFIX)$(Services.ActionManager.ACTION_ADD_CHARACTER_SHEET)"
            );
            grid.add (add_character_sheet_button);
#endif

#if CHUNK_COVER
            var add_cover_button = create_model_button (
                _("Cover"),
                Models.ChunkType.COVER.to_icon_name (),
                @"$(Services.ActionManager.ACTION_PREFIX)$(Services.ActionManager.ACTION_ADD_COVER)"
            );
            grid.add (add_cover_button);
#endif

#if CHUNK_NOTE
            var add_note_button = create_model_button (
                _("Note"),
                Models.ChunkType.NOTE.to_icon_name (),
                @"$(Services.ActionManager.ACTION_PREFIX)$(Services.ActionManager.ACTION_ADD_NOTE)"
            );
            grid.add (add_note_button);
#endif

#if IMPORT_ENABLED
            var import_button = create_model_button (
                _("Import"),
                "document-import-symbolic",
                @"$(Services.ActionManager.ACTION_PREFIX)$(Services.ActionManager.ACTION_IMPORT)"
            );
#endif

#if IMPORT_ENABLED
            grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
            grid.add (import_button);
#endif

            grid.show_all ();

            var popover = new Gtk.PopoverMenu ();
            popover.add (grid);

            return popover;
        }

        private Gtk.ModelButton create_model_button (string text, string? icon, string? accels = null) {
            var button = new Gtk.ModelButton ();
            button.get_child ().destroy ();
            var label = new Granite.AccelLabel.from_action_name (text, accels);

            if (icon != null) {
                var image = new Gtk.Image.from_icon_name (icon, Gtk.IconSize.MENU);
                image.margin_end = 6;
                label.attach_next_to (
                    image,
                    label.get_child_at (0, 0),
                    Gtk.PositionType.LEFT
                );
            }

            button.add (label);
            button.action_name = accels;
            button.sensitive = true;

            return button;
        }

        protected void update_subtitle () {
            subtitle = document.filename + (has_changes ? " (" + _ ("modified") + ")" : "");
        }

        protected void update_ui () {
            subtitle = document_manager.has_document ? document_manager.document.title : null;
            document_settings_button.sensitive = document_manager.has_document;
            menu_button.sensitive = document_manager.has_document;
            add_element_button.sensitive = document_manager.has_document;
            export_button.sensitive = document_manager.has_document;
        }
    }
}
