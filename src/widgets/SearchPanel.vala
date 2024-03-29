/*
 * Copyright 2022 Andrea Coronese <sixpounder@protonmail.com>
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
    public class SearchPanel : Gtk.Revealer {
        public weak Services.AppSettings settings { get; set; }
        public weak Manuscript.Window parent_window { get; construct; }

        public Gtk.Grid grid;
        public Gtk.SearchEntry search_entry;
        public Gtk.SearchEntry replace_entry;
        public Gtk.Button replace_tool_button;
        public Gtk.Button replace_all_tool_button;
        public Gtk.TextBuffer? text_buffer = null;
        public Gtk.SourceSearchContext search_context = null;

        public signal void result (Gtk.TextBuffer buffer, Gtk.TextIter iter);

        public SearchPanel (Manuscript.Window parent_window) {
            Object (
                parent_window: parent_window
            );
        }

        ~ SearchPanel () {
            //  if (text_buffer != null && text_buffer.ref_count > 0) {
            //      text_buffer.unref ();
            //  }
        }

        construct {
            valign = Gtk.Align.START;
            vexpand = false;
            hexpand = true;
            transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;

            settings = Services.AppSettings.get_default ();

            replace_entry = new Gtk.SearchEntry ();
            replace_entry.hexpand = true;
            replace_entry.placeholder_text = _("Replace with…");
            replace_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.PRIMARY, "edit-symbolic");
            replace_entry.activate.connect (on_replace_entry_activate);

            replace_tool_button = new Gtk.Button.with_label (_("Replace"));
            replace_tool_button.clicked.connect (on_replace_entry_activate);

            replace_all_tool_button = new Gtk.Button.with_label (_("Replace all"));
            replace_all_tool_button.clicked.connect (on_replace_all_entry_activate);

            grid = new Gtk.Grid ();
            grid.row_spacing = 6;
            grid.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);

            //  search_entry_item ();
            search_entry = new Gtk.SearchEntry ();
            search_entry.get_style_context ().add_class ("p-1");
            search_entry.hexpand = true;
            search_entry.placeholder_text = _("Find…");
            search_entry.set_icon_from_icon_name (Gtk.EntryIconPosition.PRIMARY, "edit-find-symbolic");
            grid.add (search_entry);

            var entry_path = new Gtk.WidgetPath ();
            entry_path.append_type (typeof (Gtk.Widget));

            var entry_context = new Gtk.StyleContext ();
            entry_context.set_path (entry_path);
            entry_context.add_class ("entry");

            search_entry.search_changed.connect (() => {
                search ();
            });

            search_entry.key_press_event.connect (on_search_entry_key_press);
            search_entry.changed.connect (on_search_entry_change);

            //  search_previous_item ();
            var tool_arrow_up = new Gtk.Button.from_icon_name ("go-up-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            tool_arrow_up.clicked.connect (search_previous);
            tool_arrow_up.tooltip_text = _("Search previous");

            //  search_next_item ();
            var tool_arrow_down = new Gtk.Button.from_icon_name ("go-down-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            tool_arrow_down.clicked.connect (search_next);
            tool_arrow_down.tooltip_text = _("Search next");

            var style_context = grid.get_style_context ();
            style_context.add_class ("searchbar");

            grid.add (tool_arrow_up);
            grid.add (tool_arrow_down);
            grid.add (replace_entry);
            grid.add (replace_tool_button);
            grid.add (replace_all_tool_button);

            add (grid);

            parent_window.document_manager.open_chunk.connect_after ((chunk) => {
                assert (chunk != null);
                unselect ();
                if (chunk is Models.TextChunk) {
                    var text_chunk = ((Models.TextChunk) chunk);
                    text_buffer = text_chunk.ensure_buffer ();
                    search_context = new Gtk.SourceSearchContext (text_buffer as Gtk.SourceBuffer, null);
                } else {
                    text_buffer = null;
                    search_context = null;
                }
            });

            parent_window.document_manager.stop_editing.connect ((chunk) => {
                unselect ();
                text_buffer = null;
                search_context = null;
            });

            if (parent_window.document_manager.has_document
                    && parent_window.document_manager.document.active_chunk != null
                    && parent_window.document_manager.document.active_chunk is Models.TextChunk) {
                text_buffer = ((Models.TextChunk) parent_window.document_manager.document.active_chunk).buffer;
                search_context = new Gtk.SourceSearchContext (text_buffer as Gtk.SourceBuffer, null);
            }
        }

        private void on_search_entry_change () {
            if (search_entry.text.length == 0) {
                search_entry.get_style_context ().remove_class (Gtk.STYLE_CLASS_ERROR);
            }
        }

        private bool on_search_entry_key_press (Gdk.EventKey event) {
            string key = Gdk.keyval_name (event.keyval);
            if (Gdk.ModifierType.SHIFT_MASK in event.state) {
                key = "<Shift>" + key;
            }

            switch (key) {
                case "<Shift>Return":
                case "Up":
                    if (search_entry.text == "") {
                        return false;
                    } else {
                        search_previous ();
                        return true;
                    }
                case "Return":
                case "Down":
                    if (search_entry.text == "") {
                        return false;
                    } else {
                        search_next ();
                        return true;
                    }
                case "Escape":
                    settings.searchbar = false;
                    unselect ();
                    return true;
                case "Tab":
                    if (search_entry.is_focus) {
                        replace_entry.grab_focus ();
                    }

                    return true;
            }

            return false;
        }

        public bool search () {
            if (search_context == null) {
                debug ("No search context is set");
                return false;
            }
            var search_string = search_entry.text;
            search_context.highlight = true;
            search_context.settings.regex_enabled = false;
            search_context.settings.search_text = search_string;
            search_context.settings.case_sensitive = false;

            if (text_buffer == null || text_buffer.text == "") {
                debug ("Can't search anything in an inexistent buffer and/or without anything to search.");
                return false;
            }

            Gtk.TextIter? start_iter;
            text_buffer.get_iter_at_offset (out start_iter, text_buffer.cursor_position);
            bool found = (search_entry.text != "" && search_entry.text in text_buffer.text);
            if (found) {
                search_entry.get_style_context ().remove_class (Gtk.STYLE_CLASS_ERROR);
                text_buffer.select_range (start_iter, start_iter);
            } else if (search_entry.text != "") {
                search_entry.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);
            }

            return true;
        }

        public void search_next () {
            Gtk.TextIter? start_iter, end_iter, end_iter_tmp;
            if (text_buffer != null) {
                text_buffer.get_selection_bounds (out start_iter, out end_iter);
                if (!search_for_iter (end_iter, out end_iter_tmp)) {
                    text_buffer.get_start_iter (out start_iter);
                    search_for_iter (start_iter, out end_iter);
                }
            }
        }

        public void search_previous () {
            Gtk.TextIter? start_iter, end_iter;
            if (text_buffer != null) {
                text_buffer.get_selection_bounds (out start_iter, out end_iter);
                if (!search_for_iter_backward (start_iter, out end_iter)) {
                    text_buffer.get_end_iter (out start_iter);
                    search_for_iter_backward (start_iter, out end_iter);
                }
            }
        }

        public void unselect () {
            if (search_context != null) {
                search_context.highlight = false;
            }
        }

        private bool search_for_iter (Gtk.TextIter? start_iter, out Gtk.TextIter? end_iter) {
            end_iter = start_iter;
#if GTKSOURCEVIEW3
            bool found = search_context.forward2 (start_iter, out start_iter, out end_iter, null);
#else
            bool found = search_context.forward (start_iter, out start_iter, out end_iter, null);
#endif
            if (found) {
                text_buffer.select_range (start_iter, end_iter);
                result (text_buffer, start_iter);
            }

            return found;
        }

        private bool search_for_iter_backward (Gtk.TextIter ? start_iter, out Gtk.TextIter ? end_iter) {
            end_iter = start_iter;
#if GTKSOURCEVIEW3
            bool found = search_context.backward2 (start_iter, out start_iter, out end_iter, null);
#else
            bool found = search_context.backward (start_iter, out start_iter, out end_iter, null);
#endif
            if (found) {
                text_buffer.select_range (start_iter, end_iter);
                result (text_buffer, start_iter);
            }

            return found;
        }

        private void on_replace_entry_activate () {
            if (text_buffer == null) {
                warning ("No valid buffer to replace");
                return;
            }

            Gtk.TextIter? start_iter, end_iter;
            text_buffer.get_iter_at_offset (out start_iter, text_buffer.cursor_position);

            if (search_for_iter (start_iter, out end_iter)) {
                string replace_string = replace_entry.text;
                try {
#if GTKSOURCEVIEW3
                    search_context.replace2 (start_iter, end_iter, replace_string, replace_string.length);
#else
                    search_context.replace (start_iter, end_iter, replace_string, replace_string.length);
#endif
                    update_replace_tool_sensitivities (search_entry.text);
                    debug ("Replace \"%s\" with \"%s\"", search_entry.text, replace_entry.text);
                } catch (Error e) {
                    critical (e.message);
                }
            }
        }

        private void on_replace_all_entry_activate () {
            if (text_buffer == null) {
                debug ("No valid buffer to replace");
                return;
            }

            string replace_string = replace_entry.text;

            try {
                search_context.replace_all (replace_string, replace_string.length);
                update_replace_tool_sensitivities (search_entry.text);
            } catch (Error e) {
                critical (e.message);
            }
        }

        private void update_replace_tool_sensitivities (string search_text) {
            replace_tool_button.sensitive = search_text != "";
            replace_all_tool_button.sensitive = search_text != "";
        }
    }
}
