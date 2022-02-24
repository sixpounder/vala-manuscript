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
    public class QuickOpenEntry: Gtk.ListBoxRow {
        public weak Manuscript.Models.DocumentChunk chunk { get; construct; }
        public bool highlighted { get; set; }
        public string query { get; construct; }

        public QuickOpenEntry (Manuscript.Models.DocumentChunk chunk, string query) {
            Object (
                chunk: chunk,
                query: query,
                highlighted: false,
                activatable: true
            );
        }

        construct {
            assert (chunk != null);

            var grid = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            grid.homogeneous = true;
            grid.halign = Gtk.Align.FILL;
            grid.get_style_context ().add_class ("quick-open-entry");

            string title = chunk.title;
            uint index_of_query_start = title.down ().index_of (query.down (), 0);
            uint index_of_query_end = index_of_query_start + query.length;

            string formatted_title = title;

            if (index_of_query_start != -1) {
                string label_start = title.substring (0, index_of_query_start);
                string label_strong = title.substring (index_of_query_start, index_of_query_end - index_of_query_start);
                string label_end = title.substring (index_of_query_end, title.length - index_of_query_end);
                StringBuilder builder = new StringBuilder ();
                builder.printf ("%s<b>%s</b>%s", label_start, label_strong, label_end);
                formatted_title = builder.str;
            }


            var title_label = new Gtk.Label (formatted_title);
            title_label.ellipsize = Pango.EllipsizeMode.END;
            title_label.use_markup = true;
            title_label.lines = 1;
            title_label.max_width_chars = 20;
            title_label.xalign = 0f;
            title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);

            var kind_label = new Gtk.Label (chunk.kind.to_string ());
            kind_label.justify = Gtk.Justification.RIGHT;
            kind_label.xalign = 1f;
            kind_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            kind_label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
#if GTK_4
            grid.append (title_label);
            grid.append (kind_label);
#else
            grid.pack_start (title_label);
            grid.pack_start (kind_label);
#endif

            add (grid);
        }
    }
}
