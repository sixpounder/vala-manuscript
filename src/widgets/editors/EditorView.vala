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
     * Groups all the items relative to a single editor view
     */
    public class EditorView: Gtk.Box, Protocols.EditorController {
        public weak Manuscript.Window parent_window { get; construct; }
        public Widgets.StatusBar status_bar { get; set; }
        public TextEditor editor { get; private set; }
        public string label { get; set; }
        public weak Models.DocumentChunk chunk { get; construct; }

        public EditorView (Manuscript.Window parent_window, Models.DocumentChunk chunk) {
            Object (
                orientation: Gtk.Orientation.VERTICAL,
                parent_window: parent_window,
                chunk: chunk,
                label: chunk.title
            );
        }

        construct {
            assert (chunk != null);
            get_style_context ().add_class ("editor-view");
            expand = true;
            homogeneous = false;
            halign = Gtk.Align.FILL;
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
            editor = new TextEditor (chunk);
            reflect_document_settings ();
            status_bar = new Widgets.StatusBar (parent_window, chunk);
            status_bar.height_request = 50;
            scrolled_container.add (editor);

            pack_start (scrolled_container);
            pack_start (status_bar, false, true, 0);

            label = chunk.title;
            chunk.notify["title"].connect (() => {
                if (chunk != null) {
                    label = chunk.title;
                }
            });

            parent_window.document_manager.document.settings.notify.connect (reflect_document_settings);

            show_all ();
        }

        protected void reflect_document_settings () {
            var font_family_string = @"$(
                parent_window.document_manager.document.settings.font_family != null
                    ? parent_window.document_manager.document.settings.font_family
                    : Constants.DEFAULT_FONT_FAMILY
            )";
            var font_size_string = @"$(
                parent_window.document_manager.document.settings.font_size != 0
                    ? parent_window.document_manager.document.settings.font_size
                    : Constants.DEFAULT_FONT_SIZE
            )px";
    
            set_font (
                Pango.FontDescription.from_string (@"
                    $(
                        font_family_string
                    )
                    $(
                        font_size_string
                    )"
                )
            );
            editor.indent = (int) parent_window.document_manager.document.settings.paragraph_start_padding;
            editor.pixels_below_lines = (int) parent_window.document_manager.document.settings.paragraph_spacing;

        }

        public void set_font (Pango.FontDescription font) {
            // TODO: use css instead
            editor.override_font (font);
        }

        public void scroll_to_cursor () {
            editor.scroll_to_cursor ();
        }

        /**
        * --------------------------------------------------------------------------------------------
        *
        *         Editor controller protocol
        *
        * --------------------------------------------------------------------------------------------
        */
        public void focus_editor () {
            editor.focus (Gtk.DirectionType.UP);
        }

        public bool has_changes () {
            return chunk != null && chunk.has_changes;
        }

        public Protocols.SearchResult[] search (string word) {
            return {};
        }

        public Gtk.TextBuffer ? get_buffer () {
            return chunk != null ? chunk.buffer : null;
        }

        public void scroll_to_search_result (Protocols.SearchResult result) {}

        public bool scroll_to_iter (
            Gtk.TextIter iter, double within_margin, bool use_align, double xalign, double yalign
        ) {
            return editor.scroll_to_iter (iter, within_margin, use_align, xalign, yalign);
        }

        public bool search_for_iter (Gtk.TextIter start_iter, out Gtk.TextIter ? end_iter) {
            return editor.search_for_iter (start_iter, out end_iter);
        }

        public bool search_for_iter_backward (Gtk.TextIter start_iter, out Gtk.TextIter ? end_iter) {
            return editor.search_for_iter_backward (start_iter, out end_iter);
        }
    }
}
