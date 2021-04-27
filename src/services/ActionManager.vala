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

        public const string ACTION_QUICK_OPEN = "action_quick_open";
        public const string ACTION_FIND = "action_find";
        public const string ACTION_ESC = "action_esc";

        public const string ACTION_ADD_CHAPTER = "action_add_chapter";
        public const string ACTION_ADD_CHARACTER_SHEET = "action_add_character_sheet";
        public const string ACTION_ADD_COVER = "action_add_cover";
        public const string ACTION_ADD_NOTE = "action_add_note";
        public const string ACTION_IMPORT = "action_import";

        private const ActionEntry[] ACTION_ENTRIES = {
            { ACTION_NEW_WINDOW, action_new_window },
            { ACTION_OPEN, action_open },
            { ACTION_SAVE, action_save },
            { ACTION_SAVE_AS, action_save_as },
            { ACTION_EXPORT, action_export },
            { ACTION_DOCUMENT_SETTINGS, action_document_settings },
            { ACTION_CLOSE_DOCUMENT, action_close_document },
            { ACTION_QUIT, action_quit },

            { ACTION_QUICK_OPEN, action_quick_open },
            { ACTION_FIND, action_find },
            { ACTION_ESC, action_esc },

            { ACTION_ADD_CHAPTER, action_add_chapter },
            { ACTION_ADD_CHARACTER_SHEET, action_add_character_sheet },
            { ACTION_ADD_COVER, action_add_cover },
            { ACTION_ADD_NOTE, action_add_note },
            { ACTION_IMPORT, action_import }
        };

        public weak Manuscript.Application application { get; construct; }
        public weak Manuscript.Window window { get; construct; }
        public weak Manuscript.Services.AppSettings settings { get; private set; }
        public SimpleActionGroup actions { get; construct; }

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
            action_accelerators.set (ACTION_QUICK_OPEN, "<Control>p");
            action_accelerators.set (ACTION_FIND, "<Control>f");
            action_accelerators.set (ACTION_QUIT, "<Control>q");
            action_accelerators.set (ACTION_ADD_CHAPTER, "<Alt>1");
            action_accelerators.set (ACTION_ADD_CHARACTER_SHEET, "<Alt>2");
            action_accelerators.set (ACTION_ADD_COVER, "<Alt>3");
            action_accelerators.set (ACTION_ADD_NOTE, "<Alt>4");
        }

        construct {
            settings = Services.AppSettings.get_default ();
            actions = new SimpleActionGroup ();
            actions.add_action_entries (ACTION_ENTRIES, this);
            window.insert_action_group ("win", actions);

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
            try {
                window.document_manager.close ();
            } catch (Models.DocumentError error) {
                critical (error.message);
            }
        }

        protected void action_export () {
            if (window.document_manager.has_document) {
                var dialog = new Manuscript.Dialogs.ExportDialog (window, window.document_manager.document);
                dialog.response.connect ((res) => {
                    if (res == Gtk.ResponseType.ACCEPT) {
                        dialog.destroy ();
                        Manuscript.Services.Notification.show (
                            _("Export succeeded"),
                            _("Your manuscript has been successfully exported")
                        );
                    } else if (res == Gtk.ResponseType.CLOSE) {
                        dialog.destroy ();
                    } else if (res == Gtk.ResponseType.NONE) {
                        dialog.start_export.begin ();
                    }
                });
                dialog.run ();
            }
        }

        protected void action_import () {}
    }
}
