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
    /**
     * Groups all the items relative to a single text editor view
     */
    public class TextEditorView: Gtk.Box, Protocols.ChunkEditor {
        public weak Manuscript.Services.AppSettings settings { get; private set; }
        public weak Manuscript.Window parent_window { get; construct; }
        public Widgets.EditorToolbar editor_toolbar { get; construct; }
        public Widgets.StatusBar status_bar { get; set; }
        public TextEditor editor { get; private set; }
        public string label { get; set; }
        public weak Models.DocumentChunk chunk { get; construct; }

        private bool enable_format_toolbar = true;

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

            editor_toolbar = new Widgets.EditorToolbar (((Models.TextChunk) chunk).buffer);

            status_bar = new Widgets.StatusBar (parent_window, chunk as Models.TextChunk);
            status_bar.height_request = 50;
            scrolled_container.add (editor);
#if GTK_4
            if (enable_format_toolbar) {
                append (format_toolbar);
            }
            append (scrolled_container);
            append (status_bar);
#else
            if (enable_format_toolbar) {
                pack_start (editor_toolbar, false, true, 0);
            }
            pack_start (scrolled_container);
            pack_start (status_bar, false, true, 0);
#endif

            connect_events ();
            update_ui ();
            show_all ();
        }

        private void connect_events () {
            chunk.notify["title"].connect (update_ui);
            chunk.notify["locked"].connect (update_ui);
            parent_window.document_manager.document.settings.notify.connect (update_ui);

            if (enable_format_toolbar) {
                editor.selection_changed.connect (update_format_toolbar);

                connect_format_buttons_events ();
            }

#if FEATURE_FOOTNOTES
            editor_toolbar.insert_note_button.clicked.connect (on_insert_note_clicked);
#endif

            settings.change.connect (update_ui);
        }

        private void connect_format_buttons_events () {
            editor_toolbar.format_bold.toggled.connect (on_bold_toggled);

            editor_toolbar.format_italic.toggled.connect (on_italic_toggled);

            editor_toolbar.format_underline.toggled.connect (on_underline_toggled);
        }

        private void disconnect_format_buttons_events () {
            editor_toolbar.format_bold.toggled.disconnect (on_bold_toggled);

            editor_toolbar.format_italic.toggled.disconnect (on_italic_toggled);

            editor_toolbar.format_underline.toggled.disconnect (on_underline_toggled);
        }

        private void on_bold_toggled () {
            apply_format (Models.TAG_NAME_BOLD);
        }

        private void on_italic_toggled () {
            apply_format (Models.TAG_NAME_ITALIC);
        }

        private void on_underline_toggled () {
            apply_format (Models.TAG_NAME_UNDERLINE);
        }

        private void reflect_document_settings () {
            editor.update_text_settings ();
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

            editor_toolbar.visible = !settings.focus_mode;

            reflect_document_settings ();
        }

        private void update_format_toolbar (Gtk.TextIter selection_start, Gtk.TextIter selection_end) {
            GLib.SList<weak Gtk.TextTag>? tags_at_selection_start = selection_start.get_tags ();
            GLib.SList<weak Gtk.TextTag>? tags_at_selection_end = selection_end.get_tags ();
            GLib.SList<weak Gtk.TextTag> intersecting_tags = null;
            if (tags_at_selection_start != null && tags_at_selection_end != null) {
                intersecting_tags = Utils.Lists.intersect (
                    (GLib.SList<weak Gtk.TextTag>) tags_at_selection_start,
                    (GLib.SList<weak Gtk.TextTag>) tags_at_selection_end
                );
            } else {
                intersecting_tags = tags_at_selection_start.copy ();
            }

            disconnect_format_buttons_events ();

            editor_toolbar.format_bold.active = false;
            editor_toolbar.format_italic.active = false;
            editor_toolbar.format_underline.active = false;

            intersecting_tags.@foreach ((tag) => {
                switch (tag.name) {
                    case Manuscript.Models.TAG_NAME_BOLD:
                        editor_toolbar.format_bold.active = true;
                    break;

                    case Manuscript.Models.TAG_NAME_ITALIC:
                        editor_toolbar.format_italic.active = true;
                    break;

                    case Manuscript.Models.TAG_NAME_UNDERLINE:
                        editor_toolbar.format_underline.active = true;
                    break;
                }
            });

            connect_format_buttons_events ();
        }

        private void apply_format (string tag_name) {
            editor.toggle_markup_for_selection (tag_name);
        }

#if FEATURE_FOOTNOTES
        private void on_insert_note_clicked () {
            editor.insert_empty_note_at_selection ();
        }
#endif

        public void lock_editor () {
            editor.sensitive = false;
            editor_toolbar.sensitive = false;
        }

        public void unlock_editor () {
            editor.sensitive = true;
            editor_toolbar.sensitive = true;
        }

        /**
        * --------------------------------------------------------------------------------------------
        *
        *         Editor controller protocol
        *
        * --------------------------------------------------------------------------------------------
        */
        public override void insert_open_quote () {
            get_buffer ().insert_at_cursor ("«", -1);
        }
        public override void insert_close_quote () {
            get_buffer ().insert_at_cursor ("»", -1);
        }

        public void focus_editor () {
            editor.grab_focus ();
        }

        public bool get_has_changes () {
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
