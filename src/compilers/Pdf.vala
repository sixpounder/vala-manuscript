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

    public enum PaperSize {
        A4,
        A5,
        A6
    }

    public class PDFCompiler : ManuscriptCompiler {
        //  private Cairo.Context context;
        //  private Cairo.PdfSurface surface;
        private double page_margin { get; set; }
        private uint page_counter = 0;
        private Cairo.Context? ctx { get; set; }
        private Cairo.PdfSurface? surface { get; set; }
        private Pango.Context pango_context { get; set; }

        internal PDFCompiler () {}

        construct {
            page_margin = 70;
        }

        public override async void compile (Manuscript.Models.Document document) {
            page_margin = Models.page_margin_get_value (document.settings.page_margin);

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
            ctx.set_antialias (Cairo.Antialias.BEST);

            pango_context = Pango.cairo_create_context (ctx);

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

            pango_context.changed ();

            var layout_width_in_pixels = Manuscript.Constants.A4_WIDHT_IN_POINTS / 0.75;
            var layout_height_in_pixels = Manuscript.Constants.A4_HEIGHT_IN_POINTS / 0.75;

            ctx.move_to (page_margin, page_margin);

            Pango.Layout layout = new Pango.Layout (pango_context);
            layout.set_width ((int) (layout_width_in_pixels * 600));
            layout.set_height ((int) (layout_height_in_pixels * 600));
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

            ctx.move_to (page_margin, -page_margin + 10);
            ctx.show_text (chunk.parent_document.settings.author_name);
        }

        private void render_chapter (Models.ChapterChunk chunk) {
            chunk.ensure_buffer ();
            new_page ();

            var layout_width = Manuscript.Constants.A4_WIDHT_IN_POINTS;
            var layout_height = Manuscript.Constants.A4_HEIGHT_IN_POINTS;

            ctx.set_source_rgb (1, 1, 1);
            ctx.fill_preserve ();
            ctx.save ();

            //
            // Render centered title
            //
            ctx.set_source_rgb (0, 0, 0);
            ctx.select_font_face (
                chunk.parent_document.settings.font_family,
                Cairo.FontSlant.NORMAL,
                Cairo.FontWeight.BOLD
            );
            ctx.set_font_size (chunk.parent_document.settings.font_size * TITLE_SCALE);
            
            ctx.move_to (page_margin, page_margin);
            Pango.Layout title_layout = Pango.cairo_create_layout (ctx);
            title_layout.set_width ((int) ((layout_width * Pango.SCALE) - (page_margin * Pango.SCALE * 2)));
            title_layout.set_alignment (Pango.Alignment.CENTER);
            title_layout.set_justify (false);
            title_layout.set_font_description (Pango.FontDescription.from_string (
                @"$(chunk.parent_document.settings.font_family) $(chunk.parent_document.settings.font_size * TITLE_SCALE)px"
            ));
            title_layout.set_indent ((int) chunk.parent_document.settings.paragraph_start_padding);
            title_layout.set_spacing ((int) chunk.parent_document.settings.line_spacing);
            // layout.set_line_spacing((int) chunk.parent_document.settings.line_spacing);
            title_layout.set_ellipsize (Pango.EllipsizeMode.NONE);
            title_layout.set_wrap (Pango.WrapMode.WORD);
            //  title_layout.set_text (chunk.title, chunk.title.length);
            var title_markup = @"<b>$(chunk.title)</b>";
            title_layout.set_markup (title_markup, title_markup.length);
            title_layout.context_changed ();

            Pango.Rectangle title_ink_rect, title_logical_rect;
            title_layout.get_extents (out title_ink_rect, out title_logical_rect);
            Pango.cairo_show_layout (ctx, title_layout);

            //
            // Render chapter body
            //
            ctx.set_font_size (chunk.parent_document.settings.font_size);
            ctx.set_source_rgb (0, 0, 0);

            ctx.select_font_face (
                chunk.parent_document.settings.font_family,
                Cairo.FontSlant.NORMAL,
                Cairo.FontWeight.NORMAL
            );
            ctx.set_font_size (chunk.parent_document.settings.font_size);
            ctx.rel_move_to (0, (title_logical_rect.height / Pango.SCALE) + chunk.parent_document.settings.paragraph_spacing);

            var buffer = chunk.buffer;

            Gtk.TextIter cursor, end_iter;
            buffer.get_start_iter (out cursor);
            buffer.get_end_iter (out end_iter);

            // Estimate number of pages needed;
            var layout = create_paragraph_layout (chunk);
            var all_text = buffer.get_text (cursor, end_iter, false);
            var max_text_length = all_text.length;
            
            StringBuilder markup_buffer = new StringBuilder.sized (max_text_length);
            layout = create_paragraph_layout (chunk);
            layout.context_changed ();

            while (!cursor.is_end ()) {
                Pango.Rectangle ink_rect, logical_rect;
                layout.get_extents (out ink_rect, out logical_rect);

                var height_limit = (layout_height * Pango.SCALE) - (page_margin * Pango.SCALE * 2);
                debug (@"$(logical_rect.height) > $(height_limit)");
                if ((logical_rect.height) > height_limit) {
                    //  debug (@"$(logical_rect.height) > $(height_limit)");
                    if (cursor.ends_word () || cursor.inside_word ()) {
                        Gtk.TextIter step = cursor;
                        cursor.backward_word_start ();
                        step.forward_word_end ();
                        var text_to_undo = buffer.get_text (cursor, step, false);
                        debug (@"Text to undo: $text_to_undo");
                        markup_buffer.erase (markup_buffer.len - text_to_undo.length, text_to_undo.length);
                        cursor = step;
                    } else {
                        cursor.backward_char ();
                        markup_buffer.erase (markup_buffer.len - 1, 1);
                        cursor.forward_char ();
                    }
                    layout.set_markup (markup_buffer.str, markup_buffer.str.length);

                    Pango.cairo_show_layout (ctx, layout);
                    markup_buffer = new StringBuilder.sized (max_text_length);
                    layout = create_paragraph_layout (chunk);
                    if (!cursor.is_end ()) {
                        new_page ();
                        layout.context_changed ();
                    }
                }

                if (cursor.starts_tag (null)) {
                    var tags = cursor.get_tags ();
                    tags.foreach ((tag) => {
                        string tag_text = Compilers.Utils.tag_name_to_markup (tag.name);
                        if (tag_text != null) {
                            markup_buffer.append (@"<$(tag_text)>");
                            Gtk.TextIter step = cursor;
                            step.forward_to_tag_toggle (tag);
                            string tagged_text = buffer.get_text (cursor, step, false);
                            markup_buffer.append (tagged_text);
                            markup_buffer.append (@"</$(tag_text)>");
                            cursor = step;
                        }
                    });
                } else if (cursor.starts_word ()) {
                    Gtk.TextIter word_start, word_end;
                    word_start = cursor;
                    word_end = word_start;
                    word_end.forward_word_end ();
                    string text = buffer.get_text (word_start, word_end, false);
                    markup_buffer.append (text);
                    cursor = word_end;
                } else {
                    unichar ch = cursor.get_char ();
                    markup_buffer.append_unichar (ch);
                    cursor.forward_char ();
                }

                layout.set_markup (markup_buffer.str, markup_buffer.str.length);
            }

            if (markup_buffer.data.length != 0) {
                Pango.cairo_show_layout (ctx, layout);
            }
        }

        private Pango.Layout create_paragraph_layout (Models.DocumentChunk chunk) {
            var layout_width = Manuscript.Constants.A4_WIDHT_IN_POINTS;
            var layout_height = Manuscript.Constants.A4_HEIGHT_IN_POINTS;
            //  debug (@"Layout size: $(layout_width_in_pixels)px x $(layout_height_in_pixels)px");

            Pango.Layout layout = Pango.cairo_create_layout (ctx);
            layout.set_width ((int) ((layout_width * Pango.SCALE) - (page_margin * Pango.SCALE * 2)));
            layout.set_height ((int) ((layout_height * Pango.SCALE - (page_margin * Pango.SCALE * 2))));
            layout.set_font_description (Pango.FontDescription.from_string (
                @"$(chunk.parent_document.settings.font_family) $(chunk.parent_document.settings.font_size * 0.75)"
            ));
            layout.set_indent ((int) chunk.parent_document.settings.paragraph_start_padding);
            layout.set_spacing ((int) chunk.parent_document.settings.line_spacing);
            // layout.set_line_spacing((int) chunk.parent_document.settings.line_spacing);
            layout.set_ellipsize (Pango.EllipsizeMode.NONE);
            layout.set_wrap (Pango.WrapMode.WORD);
            layout.set_justify (true);

            return layout;
        }

        private void new_page () {
            if (page_counter != 0) {
                ctx.show_page ();
                ctx.move_to (page_margin, page_margin);
            }


            page_counter ++;
        }
    }
}
