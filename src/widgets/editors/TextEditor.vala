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

    enum TextMarkup {
        ITALIC,
        BOLD
    }
    public class TextEditor : Gtk.SourceView, Protocols.ChunkEditor {
        public bool has_changes { get; private set; }
        public Gtk.SourceSearchContext search_context = null;
        protected weak Models.TextChunkBase _chunk;
        protected Gtk.CssProvider font_style_provider;
        protected Services.AppSettings settings = Services.AppSettings.get_default ();

        public TextEditor (Models.TextChunkBase chunk) {
            Object (
                chunk: chunk,
                has_focus: true,
                pixels_inside_wrap: 0,
                pixels_below_lines: 20,
                wrap_mode: Gtk.WrapMode.WORD,
                expand: true,
                populate_all: true
            );

            try {
                init_editor ();
                connect_events ();
            } catch (GLib.Error e) {
                error ("Cannot instantiate editor view: " + e.message);
            }
        }

        ~ TextEditor () {
            settings.change.disconnect (on_setting_change);
            destroy.disconnect (on_destroy);
            populate_popup.disconnect (populate_context_menu);
        }

        public weak Models.TextChunkBase chunk {
            get {
                return _chunk;
            }
            set {
                _chunk = value;
                debug (@"Loading buffer for $(_chunk.title)");
                load_buffer (_chunk.buffer);
            }
        }

        private void connect_events () {
            settings.change.connect (on_setting_change);
            destroy.connect (on_destroy);
            populate_popup.connect (populate_context_menu);
        }

        private void populate_context_menu (Gtk.Menu menu) {
            Gtk.MenuItem bold_menu_item = new Gtk.MenuItem.with_label (_("Bold"));
            bold_menu_item.activate.connect (() => {
                markup_for_selection (TextMarkup.BOLD);
            });
            Gtk.MenuItem italic_menu_item = new Gtk.MenuItem.with_label (_("Italic"));
            italic_menu_item.activate.connect (() => {
                markup_for_selection (TextMarkup.ITALIC);
            });

            menu.prepend (new Gtk.SeparatorMenuItem ());
            menu.prepend (italic_menu_item);
            menu.prepend (bold_menu_item);
            menu.show_all ();
        }

        private void markup_for_selection (TextMarkup markup) {
            Gtk.TextIter selection_start, selection_end;
            var has_selection = buffer.get_selection_bounds (out selection_start, out selection_end);
            string tag_name = "";
            switch (markup) {
                case TextMarkup.ITALIC:
                    tag_name = "italic";
                break;

                case TextMarkup.BOLD:
                    tag_name = "bold";
                break;

                default:
                break;
            }
            if (tag_name != "" && has_selection) {
                buffer.apply_tag_by_name (tag_name, selection_start, selection_end);
            }
        }

        /** Simple cubic eased scrolling for the editor view */
        public void scroll_down () {
            var clock = get_frame_clock ();
            var duration = 200;

            var start = vadjustment.get_value ();
            var end = vadjustment.get_upper () - vadjustment.get_page_size ();
            var start_time = clock.get_frame_time ();
            var end_time = start_time + 1000 * duration;

            add_tick_callback ( (widget, frame_clock) => {
                var now = frame_clock.get_frame_time ();
                if (now < end_time && vadjustment.get_value () != end) {
                    double t = (now - start_time) / (end_time - start_time);
                    t = ease_out_cubic (t);
                    vadjustment.set_value (start + t * (end - start) );
                    return true;
                } else {
                    vadjustment.set_value (end);
                    return false;
                }
            } );
        }

        public void scroll_to_cursor () {
            scroll_to_mark (buffer.get_insert (), 0.0, true, 0.0, 0.5);
        }

        public void set_font (string font_family, int64 font_size) {
            try {
                // Regenerate provider with the desired font
                font_style_provider.load_from_data (@"
                    .manuscript-text-editor {
                        font-family: $font_family;
                        font-size: $(font_size)px;
                    }
                ");
            } catch (Error e) {
                warning (e.message);
            }
        }

        protected void init_editor () throws GLib.Error {
            font_style_provider = new Gtk.CssProvider ();
            get_style_context ().add_provider (font_style_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            get_style_context ().add_class ("manuscript-text-editor");
            insert_spaces_instead_of_tabs = true;
            right_margin = 100;
            left_margin = 100;
            top_margin = 50;
            bottom_margin = 50;
            wrap_mode = Gtk.WrapMode.WORD_CHAR;
            indent = 20;
            input_hints = Gtk.InputHints.SPELLCHECK | Gtk.InputHints.NO_EMOJI;
            search_context = new Gtk.SourceSearchContext (buffer as Gtk.SourceBuffer, null);
        }

        protected void load_buffer (Gtk.SourceBuffer new_buffer) {
            buffer = new_buffer;
            update_settings (null);
        }

        protected void update_settings (string ? key = null) {
            if (buffer != null) {
                if (settings.focus_mode) {
                    focus_mode_update_highlight ();
                    buffer.notify["cursor-position"].connect (focus_mode_update_highlight);
                } else {
                    Gtk.TextIter start, end;
                    string focused_tag;
                    string dimmed_tag;
                    if (settings.prefer_dark_style) {
                        focused_tag = "dark-focused";
                        dimmed_tag = "dark-dimmed";
                    } else {
                        focused_tag = "light-focused";
                        dimmed_tag = "light-dimmed";
                    }
                    buffer.get_bounds (out start, out end);
                    buffer.remove_tag (buffer.tag_table.lookup (focused_tag), start, end);
                    buffer.remove_tag (buffer.tag_table.lookup (dimmed_tag), start, end);
                    buffer.notify["cursor-position"].disconnect (focus_mode_update_highlight);
                }
            } else {
                warning ("Settings not updated, current buffer is null");
            }
        }

        protected void unselect (Gtk.TextBuffer buffer) {
            if (buffer.has_selection) {}
        }

        /**
         * Updates text iters to highlight the current sentence and dim other parts.
         */
        protected void focus_mode_update_highlight () {
            Gtk.TextIter cursor_iter;
            Gtk.TextIter start, end;

            buffer.get_bounds (out start, out end);

            var cursor = this.buffer.get_insert ();
            buffer.get_iter_at_mark (out cursor_iter, cursor);

            if (cursor != null) {
                Gtk.TextIter sentence_start = cursor_iter;
                Gtk.TextIter sentence_end = cursor_iter;

                if (cursor_iter != start) {
                    if (!sentence_start.starts_sentence ()) {
                        sentence_start.backward_sentence_start ();
                    }
                }

                if (cursor_iter != end) {
                    if (!sentence_end.ends_sentence ()) {
                        sentence_end.forward_sentence_end ();
                    }
                }

                string focused_tag;
                string dimmed_tag;
                if (settings.prefer_dark_style) {
                    focused_tag = "dark-focused";
                    dimmed_tag = "dark-dimmed";
                } else {
                    focused_tag = "light-focused";
                    dimmed_tag = "light-dimmed";
                }

                buffer.remove_tag (buffer.tag_table.lookup (focused_tag), start, end);
                buffer.apply_tag (buffer.tag_table.lookup (dimmed_tag), start, end);
                buffer.apply_tag (buffer.tag_table.lookup (focused_tag), sentence_start, sentence_end);

                scroll_to_cursor ();
            }
        }

        public async bool search_for_iter (Gtk.TextIter ? start_iter, out Gtk.TextIter ? end_iter) {
            end_iter = start_iter;
            try {
                bool found = yield search_context.forward_async (start_iter, null, out start_iter, out end_iter);
                if (found) {
                    buffer.select_range (start_iter, end_iter);
                    scroll_to_iter (start_iter, 0, false, 0, 0);
                }

                return found;
            } catch (Error e) {
                warning (e.message);
                return false;
            }
        }

        public async bool search_for_iter_backward (Gtk.TextIter ? start_iter, out Gtk.TextIter ? end_iter) {
            end_iter = start_iter;
            try {
                bool found = yield search_context.backward_async (start_iter, null, out start_iter, out end_iter);
                if (found) {
                    buffer.select_range (start_iter, end_iter);
                    scroll_to_iter (start_iter, 0, false, 0, 0);
                }

                return found;
            } catch (Error e) {
                warning (e.message);
                return false;
            }
        }

        protected void on_setting_change (string key) {
            update_settings (key);
        }

        protected void on_document_change () {
            has_changes = true;
        }

        protected void on_document_saved (string to_path) {
            has_changes = false;
        }

        protected void on_destroy () {
            settings.change.disconnect (on_setting_change);
        }
    }
}
