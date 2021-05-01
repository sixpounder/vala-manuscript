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

namespace Manuscript.Compilers {

    const double TITLE_SCALE = 1.2;
    const int DPI = 72;

    public class PDFCompiler : ManuscriptCompiler {
        //  private Cairo.Context context;
        //  private Cairo.PdfSurface surface;
        private double page_margin { get; set; }
        private uint page_counter = 0;
        private Cairo.Context? ctx { get; set; }
        private Cairo.PdfSurface? surface { get; set; }

        internal PDFCompiler () {}

        construct {
            page_margin = 70;
        }

        public override async void compile (Manuscript.Models.Document document) {
            surface = new Cairo.PdfSurface (
                filename,
                Manuscript.Constants.A4_WIDHT_IN_POINTS,
                Manuscript.Constants.A4_HEIGHT_IN_POINTS
            );

            //  surface.set_metadata (Cairo.PdfMetadata.TITLE, document.title);
            //  surface.set_metadata (Cairo.PdfMetadata.CREATE_DATE, new DateTime.now ().to_string ());
            //  surface.set_metadata (Cairo.PdfMetadata.AUTHOR, document.settings.author_name);

            double x_scale, y_scale;
            surface.get_device_scale (out x_scale, out y_scale);

            ctx = new Cairo.Context (surface);

            ctx.select_font_face (
                document.settings.font_family,
                Cairo.FontSlant.NORMAL,
                Cairo.FontWeight.NORMAL
            );

            var covers = document.iter_chunks_by_type (Models.ChunkType.COVER);
            covers.foreach ((c) => {
                render_chunk (c);
                return true;
            });

            var chapters = document.iter_chunks_by_type (Models.ChunkType.CHAPTER);
            chapters.@foreach ((c) => {
                render_chunk (c);
                return true;
            });
        }

        private void render_chunk (Models.DocumentChunk chunk) {
            switch (chunk.kind) {
                case Manuscript.Models.ChunkType.CHAPTER:
                    render_chapter ((Models.ChapterChunk) chunk);
                    break;
                case Manuscript.Models.ChunkType.COVER:
                    render_cover ((Models.CoverChunk) chunk);
                    break;
                case Manuscript.Models.ChunkType.NOTE:
                    break;
                case Manuscript.Models.ChunkType.CHARACTER_SHEET:
                    break;
                default:
                    break;
            }
        }

        private void render_cover (Models.CoverChunk chunk) {
            new_page ();

            var layout_width_in_pixels = Manuscript.Constants.A4_WIDHT_IN_POINTS / 0.75;
            var layout_height_in_pixels = Manuscript.Constants.A4_HEIGHT_IN_POINTS / 0.75;

            ctx.move_to (page_margin, page_margin);

            Pango.Layout layout = Pango.cairo_create_layout (ctx);
            //  layout.set_width ((int) (layout_width_in_pixels);
            //  layout.set_height ((int) layout_height_in_pixels);
            layout.set_font_description (Pango.FontDescription.from_string (
                @"$(chunk.parent_document.settings.font_family) 36px"
            ));
            layout.set_indent ((int) chunk.parent_document.settings.paragraph_start_padding);
            layout.set_spacing ((int) chunk.parent_document.settings.line_spacing);
            layout.set_ellipsize (Pango.EllipsizeMode.NONE);
            layout.set_wrap (Pango.WrapMode.WORD);
            layout.set_alignment (Pango.Alignment.CENTER);

            layout.set_text (chunk.parent_document.title, chunk.parent_document.title.length);

            layout.context_changed ();

            Pango.cairo_show_layout (ctx, layout);

            ctx.move_to (page_margin, 700);
            ctx.show_text (chunk.parent_document.settings.author_name);
        }

        private void render_chapter (Models.ChapterChunk chunk) {
            chunk.ensure_buffer ();

            new_page ();
            ctx.set_antialias (Cairo.Antialias.BEST);
            ctx.set_source_rgb (1, 1, 1);
            ctx.fill_preserve ();
            ctx.save ();

            // Render centered title
            ctx.set_source_rgb (0, 0, 0);
            ctx.select_font_face (
                chunk.parent_document.settings.font_family,
                Cairo.FontSlant.NORMAL,
                Cairo.FontWeight.BOLD
            );
            ctx.set_font_size (chunk.parent_document.settings.font_size * TITLE_SCALE);
            Cairo.TextExtents extents;
            ctx.text_extents (chunk.title, out extents);
            ctx.move_to ((Manuscript.Constants.A4_WIDHT_IN_POINTS / 2) - ((extents.width / 2) + extents.x_bearing), page_margin);
            ctx.show_text (chunk.title);

            // Render chapter body
            ctx.set_font_size (chunk.parent_document.settings.font_size);
            ctx.set_source_rgb (0, 0, 0);

            ctx.select_font_face (
                chunk.parent_document.settings.font_family,
                Cairo.FontSlant.NORMAL,
                Cairo.FontWeight.NORMAL
            );
            ctx.set_font_size (chunk.parent_document.settings.font_size);

            var buffer = chunk.buffer;
            Gtk.TextIter cursor;
            buffer.get_start_iter (out cursor);

            var layout = create_paragraph_layout (chunk);

            Gtk.TextIter start_iter, end_iter;
            buffer.get_start_iter (out start_iter);
            buffer.get_end_iter (out end_iter);
            var text = buffer.get_text (start_iter, end_iter, true);
            layout.set_text (text, text.length);

            ctx.move_to (page_margin, 140);
            Pango.cairo_show_layout (ctx, layout);
        }

        private Pango.Layout create_paragraph_layout (Models.DocumentChunk chunk) {
            var layout_width_in_pixels = Manuscript.Constants.A4_WIDHT_IN_POINTS / 0.75;
            var layout_height_in_pixels = Manuscript.Constants.A4_HEIGHT_IN_POINTS / 0.75;
            debug (@"Layout size: $layout_width_in_pixels x $layout_height_in_pixels");
    
            Pango.Layout layout = Pango.cairo_create_layout (ctx);
            //  layout.set_width ((int) layout_width_in_pixels);
            //  layout.set_height ((int) layout_height_in_pixels);
            layout.set_font_description (Pango.FontDescription.from_string (
                @"$(chunk.parent_document.settings.font_family) $(chunk.parent_document.settings.font_size)px"
            ));
            layout.set_indent ((int) chunk.parent_document.settings.paragraph_start_padding);
            layout.set_spacing ((int) chunk.parent_document.settings.line_spacing);
            layout.set_ellipsize (Pango.EllipsizeMode.NONE);
            layout.set_wrap (Pango.WrapMode.WORD);
            layout.set_justify (true);

            return layout;
        }

        private void new_page () {
            if (page_counter != 0) {
                ctx.show_page ();
            }

            page_counter ++;
        }
    }
}
