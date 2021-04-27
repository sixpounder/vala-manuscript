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
    public class PDFCompiler : ManuscriptCompiler {
        private Cairo.Context context;
        private Cairo.PdfSurface surface;
        private double page_margin { get; set; }

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

            context = new Cairo.Context (surface);

            var covers = document.iter_chunks_by_type (Models.ChunkType.COVER);
            covers.foreach((c) => {
                render_chunk(c, context);
                return true;
            });

            var chapters = document.iter_chunks_by_type (Models.ChunkType.CHAPTER);
            chapters.@foreach((c) => {
                render_chunk(c, context);
                return true;
            });
        }

        private void render_chunk (Models.DocumentChunk chunk, Cairo.Context ctx) {
            switch (chunk.kind) {
                case Manuscript.Models.ChunkType.CHAPTER:
                    render_chapter ((Models.ChapterChunk) chunk, ctx);
                    break;
                case Manuscript.Models.ChunkType.COVER:
                    break;
                case Manuscript.Models.ChunkType.NOTE:
                    break;
                case Manuscript.Models.ChunkType.CHARACTER_SHEET:
                    break;
                default:
                    break;
            }
        }

        private void render_chapter (Models.ChapterChunk chunk, Cairo.Context ctx) {
            ctx.set_source_rgb (1, 1, 1);
            ctx.fill_preserve ();
            ctx.save ();

            // Render centered title
            ctx.set_source_rgb (0, 0, 0);
            ctx.select_font_face (chunk.parent_document.settings.font_family, Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            ctx.set_font_size (chunk.parent_document.settings.font_size * 1.2);            
            Cairo.TextExtents extents;
            ctx.text_extents (chunk.title, out extents);
            ctx.move_to ((Manuscript.Constants.A4_WIDHT_IN_POINTS / 2) - ((extents.width / 2) + extents.x_bearing), 70);
            ctx.show_text (chunk.title);

            // Render chapter body
            ctx.move_to (page_margin, 140);
            ctx.set_font_size (chunk.parent_document.settings.font_size);
            ctx.set_source_rgb (0, 0, 0);
            ctx.show_text (chunk.buffer.text);
            ctx.show_page ();
            
        }
    }
}
