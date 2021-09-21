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

namespace Manuscript.Services {

    public class ActionManager : Object {
        public static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

        public const string ACTION_PREFIX = "win.";
        public const string ACTION_NEW_WINDOW = "action_new_window";
        public const string ACTION_OPEN = "action_open";
        public const string ACTION_SAVE = "action_save";
        public const string ACTION_SAVE_AS = "action_save_as";
        public const string ACTION_EXPORT = "action_export";
        public const string ACTION_DOCUMENT_SETTINGS = "action_document_settings";
        public const string ACTION_CLOSE_DOCUMENT = "action_close_document";
        public const string ACTION_QUIT = "action_quit";

        public const string ACTION_FOCUS_MODE = "action_focus_mode";
        public const string ACTION_QUICK_OPEN = "action_quick_open";
        public const string ACTION_FIND = "action_find";
        public const string ACTION_ESC = "action_esc";

        public const string ACTION_ADD_CHAPTER = "action_add_chapter";
        public const string ACTION_ADD_CHARACTER_SHEET = "action_add_character_sheet";
        public const string ACTION_ADD_COVER = "action_add_cover";
        public const string ACTION_ADD_NOTE = "action_add_note";
        public const string ACTION_IMPORT = "action_import";

        public const string ACTION_ZOOM_IN_FONT = "action_zoom_in_font";
        public const string ACTION_ZOOM_OUT_FONT = "action_zoom_out_font";
        public const string ACTION_ZOOM_DEFAULT_FONT = "action_zoom_default_font";

        public const string ACTION_FORMAT_BOLD = "action_format_bold";
        public const string ACTION_FORMAT_ITALIC = "action_format_italic";
        public const string ACTION_FORMAT_UNDERLINE = "action_format_underline";

        public const string ACTION_QUOTE_OPEN = "action_quote_open";
        public const string ACTION_QUOTE_CLOSE = "action_quote_close";

        public const string ACTION_OPEN_EXPORT_FOLDER = "action_open_export_folder";

        private const ActionEntry[] WIN_ACTION_ENTRIES = {
            { ACTION_NEW_WINDOW, action_new_window },
            { ACTION_OPEN, action_open },
            { ACTION_SAVE, action_save },
            { ACTION_SAVE_AS, action_save_as },
            { ACTION_EXPORT, action_export },
            { ACTION_DOCUMENT_SETTINGS, action_document_settings },
            { ACTION_CLOSE_DOCUMENT, action_close_document },
            { ACTION_QUIT, action_quit },

            { ACTION_FOCUS_MODE, action_focus_mode },
            { ACTION_QUICK_OPEN, action_quick_open },
            { ACTION_FIND, action_find },
            { ACTION_ESC, action_esc },

            { ACTION_ADD_CHAPTER, action_add_chapter },
            { ACTION_ADD_CHARACTER_SHEET, action_add_character_sheet },
            { ACTION_ADD_COVER, action_add_cover },
            { ACTION_ADD_NOTE, action_add_note },
            { ACTION_IMPORT, action_import },

            { ACTION_FORMAT_BOLD, action_format_bold },
            { ACTION_FORMAT_ITALIC, action_format_italic },
            { ACTION_FORMAT_UNDERLINE, action_format_underline },

            { ACTION_QUOTE_OPEN, action_quote_open },
            { ACTION_QUOTE_CLOSE, action_quote_close },

            { ACTION_ZOOM_OUT_FONT, action_zoom_out_font },
            { ACTION_ZOOM_IN_FONT, action_zoom_in_font },
            { ACTION_ZOOM_DEFAULT_FONT, action_zoom_default_font },
        };

        public weak Manuscript.Application application { get; construct; }
        public weak Manuscript.Window window { get; construct; }
        public weak Manuscript.Services.AppSettings settings { get; private set; }
        public SimpleActionGroup window_actions { get; construct; }

        public ActionManager (Manuscript.Application app, Manuscript.Window window) {
            Object (
                application: app,
                window: window
            );
        }

        static construct {
            action_accelerators.set (ACTION_NEW_WINDOW, "<Control>n");
            action_accelerators.set (ACTION_OPEN, "<Control>o");
            action_accelerators.set (ACTION_SAVE, "<Control>s");
            action_accelerators.set (ACTION_SAVE_AS, "<Control><Shift>s");
            action_accelerators.set (ACTION_DOCUMENT_SETTINGS, "<Control>comma");
            action_accelerators.set (ACTION_CLOSE_DOCUMENT, "<Control><alt>c");
            action_accelerators.set (ACTION_FOCUS_MODE, "<Control><Shift>p");
            action_accelerators.set (ACTION_QUICK_OPEN, "<Control>p");
            action_accelerators.set (ACTION_FIND, "<Control>f");
            action_accelerators.set (ACTION_QUIT, "<Control>q");
            action_accelerators.set (ACTION_ADD_CHAPTER, "<Alt>1");
            action_accelerators.set (ACTION_ADD_CHARACTER_SHEET, "<Alt>2");
            action_accelerators.set (ACTION_ADD_COVER, "<Alt>3");
            action_accelerators.set (ACTION_ADD_NOTE, "<Alt>4");
            action_accelerators.set (ACTION_ZOOM_IN_FONT, "<Control>plus");
            action_accelerators.set (ACTION_ZOOM_OUT_FONT, "<Control>minus");
            action_accelerators.set (ACTION_ZOOM_DEFAULT_FONT, "<Control>0");
            action_accelerators.set (ACTION_FORMAT_BOLD, "<Control>b");
            action_accelerators.set (ACTION_FORMAT_ITALIC, "<Control>i");
            action_accelerators.set (ACTION_FORMAT_UNDERLINE, "<Control>u");
            action_accelerators.set (ACTION_QUOTE_OPEN, "<Control>" + Gdk.keyval_name (Gdk.Key.less));
            action_accelerators.set (ACTION_QUOTE_CLOSE, "<Control>" + Gdk.keyval_name (Gdk.Key.greater));
        }

        construct {
            settings = Services.AppSettings.get_default ();
            window_actions = new SimpleActionGroup ();
            window_actions.add_action_entries (WIN_ACTION_ENTRIES, this);
            window.insert_action_group ("win", window_actions);

            foreach (var action in action_accelerators.get_keys ()) {
                application.set_accels_for_action (ACTION_PREFIX + action, action_accelerators[action].to_array ());
            }
        }

        protected void action_new_window () {
            application.new_window ();
        }

        protected void action_open () {
            window.open_file_dialog ();
        }

        protected void action_save () {
            window.document_manager.save.begin ();
        }

        protected void action_save_as () {
            window.document_manager.save_as ();
        }

        protected void action_quit () {
            if (window != null) {
                window.close ();
            }
        }

        protected void action_focus_mode () {
            settings.focus_mode = !settings.focus_mode;
        }

        protected void action_quick_open () {
            assert (window != null);
            window.show_quick_open_panel ();
        }

        protected void action_find () {
            settings.searchbar = !settings.searchbar;
        }

        protected void action_esc () {
            if (settings.searchbar) {
                settings.searchbar = false;
            }
        }

        protected void action_add_chapter () {
            window.document_manager.add_chunk (
                Models.DocumentChunk.new_for_document (window.document_manager.document, Models.ChunkType.CHAPTER)
            );
        }

        protected void action_add_character_sheet () {
            window.document_manager.add_chunk (
                Models.DocumentChunk.new_for_document (
                    window.document_manager.document,
                    Models.ChunkType.CHARACTER_SHEET
                )
            );
        }

        protected void action_add_cover () {
            window.document_manager.add_chunk (
                Models.DocumentChunk.new_for_document (window.document_manager.document, Models.ChunkType.COVER)
            );
        }

        protected void action_add_note () {
            window.document_manager.add_chunk (
                Models.DocumentChunk.new_for_document (window.document_manager.document, Models.ChunkType.NOTE)
            );
        }

        protected void action_document_settings () {
            window.show_document_settings ();
        }

        protected void action_close_document () {
            window.document_manager.close.begin ((obj, res) => {
                try {
                    window.document_manager.close.end (res);
                } catch (Models.DocumentError error) {
                    critical (error.message);
                }
            });
        }

        protected void action_export () {
            if (window.document_manager.has_document) {
                var dialog = new Manuscript.Dialogs.ExportDialog (window, window.document_manager.document);
                dialog.response.connect ((res) => {
                    if (res == Gtk.ResponseType.CLOSE) {
                        dialog.destroy ();
                    } else if (res == Gtk.ResponseType.NONE) {
                        dialog.start_export.begin ((obj, res) => {
                            try {
                                dialog.start_export.end (res);
                                dialog.destroy ();
                                if (!application.has_focus) {
                                    Manuscript.Services.Notification.show (
                                        GLib.NotificationPriority.NORMAL,
                                        _("Export succeeded"),
                                        _("Your manuscript has been successfully exported"),
                                        new Variant.string (""),
                                        _("View file"),
                                        @"app.$ACTION_OPEN_EXPORT_FOLDER"
                                    );
                                }
                            } catch (Compilers.CompilerError e) {
                                critical (e.message);
                            }
                        });
                    }
                });
                dialog.run ();
            }
        }

        protected void action_import () {
            var dialog = new Dialogs.ImportDialog (window, window.document_manager.document);
            switch (dialog.run ()) {
                case Gtk.ResponseType.ACCEPT:
                    debug ("Importing manuscript");
                break;
                default:
                break;
            }
        }

        protected void action_zoom_in_font () {
            settings.text_scale_factor = (settings.text_scale_factor + 0.1)
                .clamp (Constants.MIN_FONT_SCALE, Constants.MAX_FONT_SCALE);
        }

        protected void action_zoom_out_font () {
            settings.text_scale_factor = (settings.text_scale_factor - 0.1)
                .clamp (Constants.MIN_FONT_SCALE, Constants.MAX_FONT_SCALE);
        }

        protected void action_zoom_default_font () {
            settings.text_scale_factor = 1.0;
        }

        protected void action_format_bold () {
            if (window.current_editor != null) {
                window.current_editor.apply_format (Manuscript.Models.TAG_NAME_BOLD);
            }
        }

        protected void action_format_italic () {
            if (window.current_editor != null) {
                window.current_editor.apply_format (Manuscript.Models.TAG_NAME_ITALIC);
            }
        }

        protected void action_format_underline () {
            if (window.current_editor != null) {
                window.current_editor.apply_format (Manuscript.Models.TAG_NAME_UNDERLINE);
            }
        }

        protected void action_quote_open () {
            if (window.current_editor != null) {
                window.current_editor.insert_open_quote ();
            }
        }

        protected void action_quote_close () {
            if (window.current_editor != null) {
                window.current_editor.insert_close_quote ();
            }
        }

        protected void action_open_export_folder () {

        }
    }
}
