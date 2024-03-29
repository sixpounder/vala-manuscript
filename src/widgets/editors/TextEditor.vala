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
    public class TextEditor : Gtk.SourceView, Protocols.ChunkEditor {
        public signal void selection_changed (Gtk.TextIter start, Gtk.TextIter end, bool collapsed);
        private Gtk.SourceSearchContext search_context = null;
        private weak Models.TextChunk _chunk;
        private Gtk.CssProvider font_style_provider;
        private Services.AppSettings settings = Services.AppSettings.get_default ();
        public signal void mark_set (Gtk.TextIter location, Gtk.TextMark mark);

        public weak Models.TextChunk chunk {
            get {
                return _chunk;
            }
            set {
                _chunk = value;
                debug (@"Loading buffer for $(_chunk.title)");
                load_buffer (_chunk.buffer);
            }
        }

        public TextEditor (Models.TextChunk chunk) {
            Object (
                chunk: chunk,
                has_focus: true,
                pixels_below_lines: (int) chunk.parent_document.settings.paragraph_spacing,
                pixels_inside_wrap: (int) chunk.parent_document.settings.line_spacing,
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
            chunk.parent_document.saved.disconnect (on_document_saved);
            buffer.changed.disconnect (on_document_change);
            buffer.apply_tag.disconnect (on_document_change);
            settings.change.disconnect (on_setting_change);
            destroy.disconnect (on_destroy);
            populate_popup.disconnect (populate_context_menu);
        }

        private void connect_events () {
            chunk.parent_document.saved.connect (on_document_saved);
            buffer.changed.connect (on_document_change);
            buffer.apply_tag.connect (on_document_change);
            if (buffer != null && buffer is Models.TextBuffer) {
                ((Models.TextBuffer) buffer).add_artifact.connect (on_artifact_added);
                ((Models.TextBuffer) buffer).remove_artifact.connect (on_artifact_removed);
            }
            settings.change.connect (on_setting_change);
            destroy.connect (on_destroy);
            populate_popup.connect (populate_context_menu);
            buffer.notify["cursor-position"].connect (on_cursor_position_change);
            //  buffer.mark_set.connect (on_mark_set);
        }

        private void on_artifact_added (Models.TextChunkArtifact artifact) {
            Gtk.TextChildAnchor anchor = buffer.create_child_anchor (artifact.end_iter);
            artifact.anchor = anchor;

            if (artifact is Models.FootNote) {
                var note = (Models.FootNote) artifact;
                var footnote_indicator = new FootNoteIndicator (note);
                add_child_at_anchor (footnote_indicator, anchor);
                footnote_indicator.popup ();
            }
        }

        private void on_artifact_removed (Models.TextChunkArtifact artifact) {
            if (artifact.anchor != null) {
                Gtk.TextIter iter;
                buffer.get_iter_at_child_anchor (out iter, artifact.anchor);
                buffer.delete_range (iter, iter);
            }
        }

        private void on_selection_changed () {
            Gtk.TextIter start, end;
            buffer.get_selection_bounds (out start, out end);
            bool collapsed = start == end;
            selection_changed (start, end, collapsed);
        }

        private void populate_context_menu (Gtk.Menu menu) {
            Gtk.MenuItem bold_menu_item = new Gtk.MenuItem.with_label (_("Bold"));
            bold_menu_item.activate.connect (() => {
                toggle_markup_for_selection (Models.TAG_NAME_BOLD);
            });
            Gtk.MenuItem italic_menu_item = new Gtk.MenuItem.with_label (_("Italic"));
            italic_menu_item.activate.connect (() => {
                toggle_markup_for_selection (Models.TAG_NAME_ITALIC);
            });
            Gtk.MenuItem underline_menu_item = new Gtk.MenuItem.with_label (_("Underline"));
            underline_menu_item.activate.connect (() => {
                toggle_markup_for_selection (Models.TAG_NAME_UNDERLINE);
            });

#if FEATURE_FOOTNOTES
            Gtk.MenuItem add_foot_note_item = new Gtk.MenuItem.with_label (_("Add footnote"));
            add_foot_note_item.activate.connect (() => {
                insert_empty_note_at_selection ();
            });
#endif

#if FEATURE_FOOTNOTES
            menu.prepend (new Gtk.SeparatorMenuItem ());
            menu.prepend (add_foot_note_item);
#endif
            menu.prepend (new Gtk.SeparatorMenuItem ());
            menu.prepend (underline_menu_item);
            menu.prepend (italic_menu_item);
            menu.prepend (bold_menu_item);
            menu.show_all ();
        }

        protected void init_editor () throws GLib.Error {
            // Ensure that buffer in chunk is built
            load_buffer (chunk.ensure_buffer ());

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
            if (new_buffer != null) {
                buffer = new_buffer;
                update_ui ();
            } else {
                warning ("Trying to set a null buffer on this editor");
            }
        }

        protected void update_ui () {
            if (buffer != null) {
                if (settings.focus_mode) {
                    focus_mode_update_highlight ();
                    //  buffer.notify["cursor-position"].connect (on_cursor_position_change);
                } else {
                    Gtk.TextIter start, end;
                    string focused_tag;
                    string dimmed_tag;
                    if (settings.prefer_dark_style) {
                        focused_tag = Models.THEME_TAG_NAME_DARK_FOCUSED;
                        dimmed_tag = Models.THEME_TAG_NAME_DARK_DIMMED;
                    } else {
                        focused_tag = Models.THEME_TAG_NAME_LIGHT_FOCUSED;
                        dimmed_tag = Models.THEME_TAG_NAME_LIGHT_DIMMED;
                    }
                    buffer.get_bounds (out start, out end);
                    buffer.remove_tag (buffer.tag_table.lookup (focused_tag), start, end);
                    buffer.remove_tag (buffer.tag_table.lookup (dimmed_tag), start, end);
                    //  buffer.notify["cursor-position"].disconnect (on_cursor_position_change);
                }
            } else {
                warning ("Settings not updated, current buffer is null");
            }
        }

        protected void unselect (Gtk.TextBuffer buffer) {
            on_selection_changed ();
        }

//  #if FEATURE_FOOTNOTES
//          private void add_foot_note () {
//              Gtk.TextIter start, end;

//              buffer.get_selection_bounds (out start, out end);
//              var note = new Models.FootNote (chunk, start.get_offset (), end.get_offset ());
//              chunk.add_artifact (note);
//          }
//  #endif

        private void on_cursor_position_change () {
            focus_mode_update_highlight ();
            on_selection_changed ();
        }

        /**
         * Updates text iters to highlight the current sentence and dim other parts.
         */
        protected void focus_mode_update_highlight () {
            if (settings.focus_mode) {
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
                        focused_tag = "theme-dark-focused";
                        dimmed_tag = "theme-dark-dimmed";
                    } else {
                        focused_tag = "theme-light-focused";
                        dimmed_tag = "theme-light-dimmed";
                    }

                    buffer.remove_tag (buffer.tag_table.lookup (focused_tag), start, end);
                    buffer.apply_tag (buffer.tag_table.lookup (dimmed_tag), start, end);
                    buffer.apply_tag (buffer.tag_table.lookup (focused_tag), sentence_start, sentence_end);

                    scroll_to_cursor ();
                }
            }
        }

        public void toggle_markup_for_selection (string tag_name) {
            Gtk.TextIter selection_start, selection_end;
            buffer.get_selection_bounds (out selection_start, out selection_end);
            var removed = false;

            buffer.begin_user_action ();
            selection_start.get_tags ().@foreach ((tag) => {
                if (tag.name == tag_name) {
                    buffer.remove_tag_by_name (tag_name, selection_start, selection_end);
                    removed = true;
                }
            });

            if (tag_name != "" && !removed) {
                buffer.apply_tag_by_name (tag_name, selection_start, selection_end);
            }
            buffer.end_user_action ();
        }

        public void insert_empty_note_at_selection () {
            Gtk.TextIter selection_start, selection_end;
            buffer.get_selection_bounds (out selection_start, out selection_end);

            var note = new Models.FootNote (chunk.buffer, selection_start.get_offset (), selection_end.get_offset ());
            chunk.buffer.add_artifact (note);
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
            if (buffer != null) {
                scroll_to_mark (buffer.get_insert (), 0.0, true, 0.0, 0.5);
            }
        }

        public void update_text_settings () {
            try {
                assert (this != null);
                assert (settings != null);
                var use_font = settings.use_document_typography
                    ? chunk.parent_document.settings.font_family != null
                        ? chunk.parent_document.settings.font_family
                        : Constants.DEFAULT_FONT_FAMILY
                    : Constants.DEFAULT_FONT_FAMILY;
                var use_size = settings.use_document_typography
                    ? chunk.parent_document.settings.font_size != 0
                        ? chunk.parent_document.settings.font_size
                        : Constants.DEFAULT_FONT_SIZE
                    : Constants.DEFAULT_FONT_SIZE;
                // Regenerate provider with the desired font
                font_style_provider.load_from_data (@"
                    .manuscript-text-editor {
                        font-family: $(use_font);
                        font-size: $(use_size * settings.text_scale_factor)pt;
                    }
                ");

                indent = settings.use_document_typography
                    ? (int) chunk.parent_document.settings.paragraph_start_padding
                    : (int) Constants.DEFAULT_PARAGRAPH_INITIAL_PADDING;

                pixels_below_lines = settings.use_document_typography
                    ? (int) chunk.parent_document.settings.paragraph_spacing
                    : (int) Constants.DEFAULT_PARAGRAPH_SPACING;

                pixels_inside_wrap = settings.use_document_typography
                    ? (int) chunk.parent_document.settings.line_spacing
                    : (int) Constants.DEFAULT_LINE_SPACING;

                // Iterates all child widgets

                this.@foreach ((child) => {
                    if (child != null && child is FootNoteIndicator) {
                        ((FootNoteIndicator) child).resize ((int) ((use_size * settings.text_scale_factor) / 0.75));
                    }
                });

            } catch (Error e) {
                warning (e.message);
            }
        }

        public override void apply_format (string tag_name) {
            toggle_markup_for_selection (tag_name);
        }

        public async bool search_for_iter (Gtk.TextIter ? start_iter, out Gtk.TextIter ? end_iter) {
            end_iter = start_iter;
            try {
#if GTKSOURCEVIEW3
                bool found = yield search_context.forward_async (start_iter, null, out start_iter, out end_iter);
#else
                bool found;
                yield search_context.forward_async (start_iter, null, out start_iter, out end_iter, out found);
#endif
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
#if GTKSOURCEVIEW3
                bool found = yield search_context.backward_async (start_iter, null, out start_iter, out end_iter);
#else
                bool found;
                yield search_context.backward_async (start_iter, null, out start_iter, out end_iter, out found);
#endif
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
            update_ui ();
        }

        protected void on_document_change () {
            chunk.has_changes = true;
        }

        protected void on_document_saved (string to_path) {
            chunk.has_changes = false;
        }

        protected void on_destroy () {
            settings.change.disconnect (on_setting_change);
        }
    }
}
