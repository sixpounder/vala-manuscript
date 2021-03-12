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
    const string CHUNK_PREVIEW_FONT = "FreeSerif 6";
    public struct Point {
        public double x;
        public double y;
    }

    public class ChunkPreview : Gtk.DrawingArea {
        private Models.DocumentChunk _chunk;
        private Gtk.Allocation allocated_size;

        public double inset { get; set; }

        public Models.DocumentChunk chunk {
            get {
                return _chunk;
            }
            set {
                if (_chunk != value) {
                    _chunk = value;
                    queue_draw ();
                }
            }
        }

        public ChunkPreview (Models.DocumentChunk ? chunk) {
            Object (
                chunk: chunk,
                inset: 10.0
            );

            get_style_context ().add_class ("chunk-preview");

            realize.connect (on_realize);
            size_allocate.connect (on_size_allocate);
            draw.connect (on_draw);
        }

        protected void on_realize () {
            //  queue_draw ();
        }

        protected void on_size_allocate (Gtk.Allocation allocation) {
            allocated_size = allocation;
        }

        protected bool on_draw (Cairo.Context cr) {
            uint width, height;
            width = get_allocated_width ();
            height = get_allocated_height ();
            draw_frame (cr);
            var context = get_style_context ();
            context.render_background (cr, 0, 0, width, height);
            if (_chunk != null) {
                cr.set_source_rgba (0, 0, 0, 1);
                cr.move_to (60, 60);
                draw_text (cr, _chunk.raw_content);
            }
            return false;
        }

        protected void draw_text (Cairo.Context cr, string text) {
            var layout = Pango.cairo_create_layout (cr);

            Pango.FontDescription font = Pango.FontDescription.from_string (CHUNK_PREVIEW_FONT);

            layout.set_font_description (font);
            layout.set_text (text, text.length);
            Pango.cairo_show_layout (cr, layout);
        }

        protected void draw_frame (Cairo.Context cr) {
            double mwidth = ((double) get_allocated_width ()) - inset;
            double mheight = ((double) get_allocated_height ()) - inset;

            Point top_left = Point () {
                x = inset,
                y = inset
            };

            Point top_right = Point () {
                x = top_left.x + mwidth,
                y = top_left.x
            };

            Point bottom_left = Point () {
                x = top_left.x,
                y = top_left.y + mheight - inset
            };

            Point bottom_right = Point () {
                x = top_right.x,
                y = top_right.y + mheight - inset
            };

            cr.set_source_rgba (0.7, 0.7, 0.7, 1);

            cr.move_to (top_left.x, top_left.y);
            cr.line_to (top_right.x, top_right.y);
            cr.stroke ();

            cr.move_to (top_right.x, top_right.y);
            cr.line_to (bottom_right.x, bottom_right.y);
            cr.stroke ();

            cr.move_to (bottom_right.x, bottom_right.y);
            cr.line_to (bottom_left.x, bottom_left.y);
            cr.stroke ();

            cr.move_to (bottom_left.x, bottom_left.y);
            cr.line_to (top_left.x, top_left.y);
            cr.stroke ();
        }
    }
}
