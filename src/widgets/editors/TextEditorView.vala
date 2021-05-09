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
    /**
     * Groups all the items relative to a single text editor view
     */
    public class TextEditorView: Gtk.Box, Protocols.ChunkEditor {
        public weak Manuscript.Services.AppSettings settings { get; private set; }
        public weak Manuscript.Window parent_window { get; construct; }
        public Widgets.FormatToolbar format_toolbar { get; construct; }
        public Widgets.StatusBar status_bar { get; set; }
        public TextEditor editor { get; private set; }
        public string label { get; set; }
        public weak Models.DocumentChunk chunk { get; construct; }

        private ulong bold_activate_event;
        private ulong italic_activate_event;
        private ulong underline_activate_event;

        public TextEditorView (Manuscript.Window parent_window, Models.DocumentChunk chunk) {
            Object (
                orientation: Gtk.Orientation.VERTICAL,
                parent_window: parent_window,
                chunk: chunk,
                label: chunk.title,
                expand: true,
                homogeneous: false,
                halign: Gtk.Align.FILL,
                valign: Gtk.Align.FILL
            );
        }

        construct {
            assert (chunk != null);
            settings = Services.AppSettings.get_default ();
            get_style_context ().add_class ("editor-view");
            Gtk.ScrolledWindow scrolled_container = new Gtk.ScrolledWindow (null, null);
            scrolled_container.kinetic_scrolling = true;
            scrolled_container.overlay_scrolling = true;
            scrolled_container.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
            scrolled_container.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
            scrolled_container.vadjustment.value_changed.connect (() => {
                Gtk.Allocation allocation;
                editor.get_allocation (out allocation);
                status_bar.update_scroll_progress (
                    scrolled_container.vadjustment.value,
                    scrolled_container.vadjustment.lower,
                    scrolled_container.vadjustment.upper - allocation.height
                );
            });
            editor = new TextEditor (chunk as Models.TextChunk);

            format_toolbar = new Widgets.FormatToolbar (((Models.TextChunk) chunk).buffer);

            status_bar = new Widgets.StatusBar (parent_window, chunk as Models.TextChunk);
            status_bar.height_request = 50;
            scrolled_container.add (editor);

            pack_start (format_toolbar, false, true, 0);
            pack_start (scrolled_container);
            pack_start (status_bar, false, true, 0);

            connect_events ();
            update_ui ();
            show_all ();
        }

        private void connect_events () {
            chunk.notify["title"].connect (update_ui);
            chunk.notify["locked"].connect (update_ui);
            editor.mark_set.connect (update_format_toolbar);
            parent_window.document_manager.document.settings.notify.connect (update_ui);

            bold_activate_event = format_toolbar.format_bold.toggled.connect (() => {
                apply_format (Models.TAG_NAME_BOLD);
            });
            italic_activate_event = format_toolbar.format_italic.toggled.connect (() => {
                apply_format (Models.TAG_NAME_ITALIC);
            });
            underline_activate_event = format_toolbar.format_underline.toggled.connect (() => {
                apply_format (Models.TAG_NAME_UNDERLINE);
            });

            settings.change.connect (reflect_document_settings);
        }

        //  private void disconnect_events () {
        //      chunk.notify["title"].disconnect (update_ui);
        //      chunk.notify["locked"].disconnect (update_ui);
        //      editor.mark_set.disconnect (update_format_toolbar);
        //      format_toolbar.format_bold.disconnect (bold_activate_event);
        //      format_toolbar.format_italic.disconnect (italic_activate_event);
        //      format_toolbar.format_underline.disconnect (underline_activate_event);
        //      settings.change.disconnect (reflect_document_settings);
        //      if (parent_window.document_manager.has_document) {
        //          parent_window.document_manager.document.settings.notify.disconnect (update_ui);
        //      }
        //  }

        private void reflect_document_settings () {
            editor.indent = (int) parent_window.document_manager.document.settings.paragraph_start_padding;
            editor.pixels_below_lines = (int) parent_window.document_manager.document.settings.paragraph_spacing;
            editor.pixels_inside_wrap = (int) parent_window.document_manager.document.settings.line_spacing;
            editor.update_font ();
        }

        public void scroll_to_cursor () {
            editor.scroll_to_cursor ();
        }

        private void update_ui () {
            if (chunk != null) {
                label = chunk.title;

                if (chunk.locked) {
                    lock_editor ();
                } else {
                    unlock_editor ();
                }
            }
            reflect_document_settings ();
        }

        private void update_format_toolbar (Gtk.TextIter location, Gtk.TextMark mark) {
            Gtk.TextIter start, end;
            editor.buffer.get_selection_bounds (out start, out end);
            GLib.SList<weak Gtk.TextTag> tags_at_selection_start = start.get_tags ();
            //  GLib.SList<weak Gtk.TextTag> tags_at_selection_end = end.get_tags ();

            //  disconnect_events ();

            format_toolbar.format_bold.active = false;
            format_toolbar.format_italic.active = false;
            format_toolbar.format_underline.active = false;

            tags_at_selection_start.@foreach ((tag) => {
                switch (tag.name) {
                    case "bold":
                        format_toolbar.format_bold.active = true;
                    break;

                    case "italic":
                        format_toolbar.format_italic.active = true;
                    break;

                    case "underline":
                        format_toolbar.format_underline.active = true;
                    break;
                }
            });

            //  connect_events ();
        }

        private void apply_format (string tag_name) {
            editor.toggle_markup_for_selection (tag_name);
        }

        public void lock_editor () {
            editor.sensitive = false;
        }

        public void unlock_editor () {
            editor.sensitive = true;
        }

        /**
        * --------------------------------------------------------------------------------------------
        *
        *         Editor controller protocol
        *
        * --------------------------------------------------------------------------------------------
        */
        public void focus_editor () {
            editor.grab_focus ();
        }

        public bool has_changes () {
            return chunk != null && chunk.has_changes;
        }

        public Protocols.SearchResult[] search (string word) {
            return {};
        }

        public Gtk.TextBuffer ? get_buffer () {
            if (chunk != null && chunk is Models.TextChunk) {
                Models.TextChunk text_chunk = chunk as Models.TextChunk;
                return text_chunk.buffer;
            } else {
                return null;
            }
        }

        public void scroll_to_search_result (Protocols.SearchResult result) {}

        public bool scroll_to_iter (
            Gtk.TextIter iter, double within_margin, bool use_align, double xalign, double yalign
        ) {
            return editor.scroll_to_iter (iter, within_margin, use_align, xalign, yalign);
        }

        public async bool search_for_iter (Gtk.TextIter start_iter, out Gtk.TextIter ? end_iter) {
            return yield editor.search_for_iter (start_iter, out end_iter);
        }

        public async bool search_for_iter_backward (Gtk.TextIter start_iter, out Gtk.TextIter ? end_iter) {
            return yield editor.search_for_iter_backward (start_iter, out end_iter);
        }
    }
}
