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

namespace Manuscript.Compilers {

    private const double TITLE_SCALE = 1.2;
    private const double PAGE_NUMBER_SCALE_FACTOR = 0.75;
    private const double POINT_SCALE = 0.75;
    private const int DPI = 72;
    private const string NOTES_FIXED_TITLE = Manuscript.Services.I18n.NOTES;
    private const string CHARACTER_SHEETS_FIXED_TITLE = Manuscript.Services.I18n.CHARACTER_SHEETS;

    public class PDFCompiler : ManuscriptCompiler {
        private weak Models.Document cached_document { get; set; }
        private uint page_counter = 0;
        private double surface_width;
        private double surface_height;
        private double page_margin { get; set; }
        private Cairo.Context? cairo_context { get; set; }
        private Cairo.PdfSurface? cairo_pdf_surface { get; set; }
        private Pango.Context pango_context { get; set; }

        internal PDFCompiler () {}

        construct {
            page_margin = 70 * POINT_SCALE;
            paper_size_in_points (options.page_size, out surface_width, out surface_height);
        }

        public override async void compile (Manuscript.Models.Document document) throws CompilerError {
            cached_document = document;
            page_margin = Models.page_margin_get_value (options.page_margin) * POINT_SCALE;

            cairo_pdf_surface = new Cairo.PdfSurface (
                filename,
                surface_width,
                surface_height
            );

            cairo_pdf_surface.set_metadata (Cairo.PdfMetadata.TITLE, document.title);
            cairo_pdf_surface.set_metadata (Cairo.PdfMetadata.CREATE_DATE, new DateTime.now ().to_string ());
            cairo_pdf_surface.set_metadata (Cairo.PdfMetadata.AUTHOR, document.settings.author_name);

            double x_scale, y_scale;
            cairo_pdf_surface.get_device_scale (out x_scale, out y_scale);

            cairo_context = new Cairo.Context (cairo_pdf_surface);
            cairo_context.set_antialias (Cairo.Antialias.BEST);

            pango_context = Pango.cairo_create_context (cairo_context);

            cairo_context.select_font_face (
                document.settings.font_family,
                Cairo.FontSlant.NORMAL,
                Cairo.FontWeight.NORMAL
            );

            render_default_cover ();

            var chapters = document.iter_chunks_by_kind (Models.ChunkType.CHAPTER);
            chapters.@foreach ((c) => {
                try {
                    if (c.included) {
                        render_chunk (c);
                    }
                } catch (CompilerError e) {
                    runtime_compile_error = e;
                }
                return runtime_compile_error == null;
            });

            if (runtime_compile_error != null) {
                throw runtime_compile_error;
            }

            var notes = document.iter_chunks_by_kind (Models.ChunkType.NOTE);
            if (notes.has_next ()) {
                render_notes_cover ();
                notes.@foreach ((c) => {
                    try {
                        if (c.included) {
                            render_chunk (c);
                        }
                    } catch (CompilerError e) {
                        runtime_compile_error = e;
                    }
                    return runtime_compile_error == null;
                });

                if (runtime_compile_error != null) {
                    throw runtime_compile_error;
                }
            }

            var character_sheets = document.iter_chunks_by_kind (Models.ChunkType.CHARACTER_SHEET);
            if (character_sheets.has_next ()) {
                render_character_sheets_cover ();
                character_sheets.@foreach ((c) => {
                    try {
                        if (c.included) {
                            render_chunk (c);
                        }
                    } catch (CompilerError e) {
                        runtime_compile_error = e;
                    }
                    return runtime_compile_error == null;
                });

                if (runtime_compile_error != null) {
                    throw runtime_compile_error;
                }
            }
        }

        private void render_chunk (Models.DocumentChunk chunk) throws CompilerError {
            if (Utils.chunk_kind_supported (chunk.kind)) {
                switch (chunk.kind) {
                    case Manuscript.Models.ChunkType.CHAPTER:
                        render_chapter ((Models.ChapterChunk) chunk);
                        break;
                    case Manuscript.Models.ChunkType.COVER:
                        break;
                    case Manuscript.Models.ChunkType.NOTE:
                        render_note ((Models.NoteChunk) chunk);
                        break;
                    case Manuscript.Models.ChunkType.CHARACTER_SHEET:
                        render_character_sheet ((Models.CharacterSheetChunk) chunk);
                        break;
                    default:
                        break;
                }
            }
        }

        private void render_page_centered_text (string text) {
            cairo_context.save ();
            new_page ();
            //  pango_context.changed ();
            var layout_width = surface_width;
            var layout_height = surface_height;

            Pango.Layout layout = new Pango.Layout (pango_context);
            layout.set_width ((int) ((layout_width * Pango.SCALE) - (page_margin * Pango.SCALE * 2)));
            layout.set_height ((int) (layout_height * Pango.SCALE - (page_margin * Pango.SCALE * 2)));
            layout.set_font_description (Pango.FontDescription.from_string (
                @"$(cached_document.settings.font_family) bold 36"
            ));
            layout.set_indent ((int) cached_document.settings.paragraph_start_padding);
            layout.set_spacing ((int) cached_document.settings.line_spacing);
            layout.set_ellipsize (Pango.EllipsizeMode.NONE);
            layout.set_wrap (Pango.WrapMode.WORD);
            layout.set_alignment (Pango.Alignment.CENTER);

            layout.set_text (text, text.length);

            Pango.Rectangle title_ink_rect, title_logical_rect;
            layout.get_extents (out title_ink_rect, out title_logical_rect);

            cairo_context.move_to (
                page_margin,
                page_margin + ((layout_height / 2) - (2 * (title_logical_rect.height / Pango.SCALE)))
            );

            layout.context_changed ();
            Pango.cairo_show_layout (cairo_context, layout);

            mark_page_number ();
            cairo_context.restore ();
        }

        private void render_default_cover () {
            new_page ();
            //  pango_context.changed ();
            var layout_width = surface_width;
            var layout_height = surface_height;

            Pango.Layout layout = new Pango.Layout (pango_context);
            layout.set_width ((int) ((layout_width * Pango.SCALE) - (page_margin * Pango.SCALE * 2)));
            layout.set_height ((int) (layout_height * Pango.SCALE - (page_margin * Pango.SCALE * 2)));
            layout.set_font_description (Pango.FontDescription.from_string (
                @"$(cached_document.settings.font_family) bold 36"
            ));
            layout.set_indent ((int) cached_document.settings.paragraph_start_padding);
            layout.set_spacing ((int) cached_document.settings.line_spacing);
            layout.set_ellipsize (Pango.EllipsizeMode.NONE);
            layout.set_wrap (Pango.WrapMode.WORD);
            layout.set_alignment (Pango.Alignment.CENTER);
            layout.set_text (cached_document.title, cached_document.title.length);

            Pango.Rectangle title_ink_rect, title_logical_rect;
            layout.get_extents (out title_ink_rect, out title_logical_rect);

            cairo_context.move_to (
                page_margin,
                page_margin + ((layout_height / 2) - (2 * (title_logical_rect.height / Pango.SCALE)))
            );

            layout.context_changed ();
            Pango.cairo_show_layout (cairo_context, layout);

            cairo_context.rel_move_to (0, 140);

            layout = new Pango.Layout (pango_context);
            layout.set_width ((int) ((layout_width * Pango.SCALE) - (page_margin * Pango.SCALE * 2)));
            layout.set_height ((int) (layout_height * Pango.SCALE - (page_margin * Pango.SCALE * 2)));
            layout.set_font_description (Pango.FontDescription.from_string (
                @"$(cached_document.settings.font_family) 16"
            ));
            layout.set_indent ((int) cached_document.settings.paragraph_start_padding);
            layout.set_spacing ((int) cached_document.settings.line_spacing);
            layout.set_ellipsize (Pango.EllipsizeMode.NONE);
            layout.set_wrap (Pango.WrapMode.WORD);
            layout.set_alignment (Pango.Alignment.CENTER);

            layout.set_text (
                cached_document.settings.author_name,
                cached_document.settings.author_name.length
            );
            layout.context_changed ();
            Pango.cairo_show_layout (cairo_context, layout);

            cairo_context.move_to (page_margin, -page_margin + 10);
            cairo_context.show_text (cached_document.settings.author_name);

            mark_page_number ();
        }

        private void render_notes_cover () {
            render_page_centered_text (NOTES_FIXED_TITLE);
        }

        private void render_character_sheets_cover () {
            render_page_centered_text (CHARACTER_SHEETS_FIXED_TITLE);
        }

        private void render_text_chunk (Models.TextChunk chunk) {
            chunk.ensure_buffer ();
            new_page ();
            mark_page_number ();

            bool on_title_page = true;
            var layout_width = surface_width;
            var layout_height = surface_height;
            //  int paragraph_spacing = (int) Math.floor (
            //      (chunk.parent_document.settings.paragraph_spacing * POINT_SCALE)
            //  );

            cairo_context.set_source_rgb (1, 1, 1);
            cairo_context.fill_preserve ();

            //
            // Render centered title
            //
            cairo_context.set_source_rgb (0, 0, 0);
            cairo_context.select_font_face (
                chunk.parent_document.settings.font_family,
                Cairo.FontSlant.NORMAL,
                Cairo.FontWeight.BOLD
            );
            cairo_context.set_font_size (chunk.parent_document.settings.font_size * TITLE_SCALE);
            cairo_context.move_to (page_margin, page_margin);

            Pango.Layout title_layout = new Pango.Layout (pango_context);
            title_layout.set_width ((int) ((layout_width * Pango.SCALE) - (page_margin * Pango.SCALE * 2)));
            title_layout.set_alignment (Pango.Alignment.CENTER);
            title_layout.set_justify (false);
            title_layout.set_font_description (Pango.FontDescription.from_string (
                @"$(chunk.parent_document.settings.font_family) $(chunk.parent_document.settings.font_size * TITLE_SCALE)" // vala-lint=line-length
            ));
            title_layout.set_indent ((int) chunk.parent_document.settings.paragraph_start_padding);
            title_layout.set_spacing ((int) chunk.parent_document.settings.line_spacing);
            title_layout.set_ellipsize (Pango.EllipsizeMode.NONE);
            title_layout.set_wrap (Pango.WrapMode.WORD);

            string title_markup = @"<b>$(chunk.title)</b>";
            title_layout.set_markup (title_markup, title_markup.length);
            title_layout.context_changed ();

            Pango.Rectangle title_ink_rect, title_logical_rect;
            title_layout.get_extents (out title_ink_rect, out title_logical_rect);
            Pango.cairo_show_layout (cairo_context, title_layout);

            //
            // Render chapter body
            //
            cairo_context.set_font_size (chunk.parent_document.settings.font_size);
            cairo_context.set_source_rgb (0, 0, 0);

            cairo_context.select_font_face (
                chunk.parent_document.settings.font_family,
                Cairo.FontSlant.NORMAL,
                Cairo.FontWeight.NORMAL
            );
            cairo_context.set_font_size (chunk.parent_document.settings.font_size);
            cairo_context.rel_move_to (
                0,
                (title_logical_rect.height / Pango.SCALE) + chunk.parent_document.settings.paragraph_spacing.clamp (40, 140) // vala-lint=line-length
            );

            var buffer = chunk.buffer;

            Gtk.TextIter cursor, end_iter;
            buffer.get_start_iter (out cursor);
            buffer.get_end_iter (out end_iter);

            Cairo.FontExtents font_extents;
            cairo_context.font_extents (out font_extents);
            var computed_line_spacing = Math.floor ((chunk.parent_document.settings.line_spacing * POINT_SCALE));
            var single_line_height = font_extents.height + computed_line_spacing;
            var max_lines_per_page = Math.ceil ((layout_height - (page_margin * 3)) / single_line_height) - 1;
            var max_lines_per_page_with_title = Math.floor (
                (layout_height - (page_margin * 3) - (title_logical_rect.height / Pango.SCALE)) / single_line_height
            ) - 2;

            var all_text = buffer.get_text (cursor, end_iter, false);
            var max_text_length = all_text.length;
            uint line_counter = 0;

            StringBuilder markup_buffer = new StringBuilder.sized (max_text_length);
            var layout = create_page_layout (chunk);

            while (!cursor.is_end ()) {
                var line_count_limit = on_title_page ? max_lines_per_page_with_title : max_lines_per_page;

                // If the line counter hits the line count limit for the page, begin a new one
                if (line_counter > line_count_limit) {

                    // If page must end, but cursor is inside a word, go back until word begin
                    // so we can 'move' it to the next page
                    if (cursor.inside_word () || cursor.ends_word ()) {
                        uint undo_chars = 0;
                        while (!cursor.starts_word ()) {
                            cursor.backward_char ();
                            undo_chars ++;
                        }
                        markup_buffer.erase (markup_buffer.len - 1 - undo_chars);
                        layout.set_markup (markup_buffer.str, markup_buffer.str.length);
                    }
                    // ----

                    // Show current layout and reset it, moving to new page
                    Pango.cairo_show_layout (cairo_context, layout);
                    mark_page_number ();
                    new_page ();
                    markup_buffer = new StringBuilder.sized (max_text_length);
                    on_title_page = false;
                    line_counter = 0;
                    layout = create_page_layout (chunk);
                    // ----
                }

                if (cursor.starts_tag (null)) {
                    var tags = cursor.get_toggled_tags (true);
                    tags.foreach ((tag) => {
                        string tag_text = Compilers.Utils.tag_name_to_markup (tag.name);
                        if (tag_text != null) {
                            markup_buffer.append (@"<$(tag_text)>");
                        }
                    });
                }

                if (cursor.ends_tag (null)) {
                    var tags = cursor.get_toggled_tags (false);
                    tags.foreach ((tag) => {
                        string tag_text = Compilers.Utils.tag_name_to_markup (tag.name);
                        if (tag_text != null) {
                            markup_buffer.append (@"</$(tag_text)>");
                        }
                    });
                }

                if (cursor.starts_word ()) {
                    // If cursor is at a natural word start, read the whole word.
                    Gtk.TextIter word_start, word_end;
                    word_start = cursor;
                    word_end = word_start;
                    word_end.forward_word_end ();
                    string text = buffer.get_text (word_start, word_end, false);
                    markup_buffer.append (GLib.Markup.escape_text (text));
                    cursor = word_end;
                } else {
                    // If not, append a single char to the buffer
                    unichar ch = cursor.get_char ();
                    markup_buffer.append_unichar (ch);
                    cursor.forward_char ();
                    if (ch == '\n') {
                        markup_buffer.append_c ('\n');
                    }
                }

                layout.set_markup (markup_buffer.str, markup_buffer.str.length);
                line_counter = layout.get_line_count ();
            }

            // Flush any remaining characters in the buffer
            if (markup_buffer.data.length != 0) {
                Pango.cairo_show_layout (cairo_context, layout);
                mark_page_number ();
            }
        }

        private void render_chapter (Models.ChapterChunk chunk) {
            render_text_chunk (chunk);
        }

        private void render_note (Models.NoteChunk chunk) {
            render_text_chunk (chunk);
        }

        private void render_character_sheet (Models.CharacterSheetChunk chunk) {
            new_page ();
            mark_page_number ();

            cairo_context.set_source_rgb (1, 1, 1);
            cairo_context.fill_preserve ();

            var layout_width = surface_width;
            //  var layout_height = surface_height;
            Cairo.FontExtents font_extents;
            cairo_context.font_extents (out font_extents);
            //  var computed_line_spacing = Math.floor ((chunk.parent_document.settings.line_spacing * POINT_SCALE));
            //  var single_line_height = font_extents.height + computed_line_spacing;
            //  var max_lines_per_page = Math.ceil ((layout_height - (page_margin * 3)) / single_line_height) - 1;
            //  uint line_counter = 0;

            //
            // Render centered title
            //
            cairo_context.set_source_rgb (0, 0, 0);
            cairo_context.select_font_face (
                chunk.parent_document.settings.font_family,
                Cairo.FontSlant.NORMAL,
                Cairo.FontWeight.BOLD
            );
            cairo_context.set_font_size (chunk.parent_document.settings.font_size * TITLE_SCALE);
            cairo_context.move_to (page_margin, page_margin);

            Pango.Layout title_layout = create_pango_layout (pango_context, chunk, (layout) => {
                layout.set_width ((int) ((layout_width * Pango.SCALE) - (page_margin * Pango.SCALE * 2)));
                layout.set_alignment (Pango.Alignment.CENTER);
                layout.set_justify (false);
                layout.set_font_description (Pango.FontDescription.from_string (
                    @"$(chunk.parent_document.settings.font_family) $(chunk.parent_document.settings.font_size * TITLE_SCALE)" // vala-lint=line-length
                ));
            });

            var title_markup = @"<b>$(Markup.escape_text (chunk.name))</b>";
            title_layout.set_markup (title_markup, title_markup.length);
            title_layout.context_changed ();

            Pango.Rectangle title_ink_rect, title_logical_rect;
            title_layout.get_extents (out title_ink_rect, out title_logical_rect);
            Pango.cairo_show_layout (cairo_context, title_layout);

            //
            // Render sheet content
            //
            cairo_context.set_font_size (chunk.parent_document.settings.font_size);
            cairo_context.set_source_rgb (0, 0, 0);

            cairo_context.select_font_face (
                chunk.parent_document.settings.font_family,
                Cairo.FontSlant.NORMAL,
                Cairo.FontWeight.NORMAL
            );
            cairo_context.set_font_size (chunk.parent_document.settings.font_size);
            cairo_context.rel_move_to (
                0,
                (title_logical_rect.height / Pango.SCALE) + chunk.parent_document.settings.paragraph_spacing.clamp (40, 140) // vala-lint=line-length
            );

            var traits_title_markup = @"<b>$(Services.I18n.TRAITS):</b>\0";
            var background_title_markup = @"<b>$(Services.I18n.BACKGROUND):</b>\0";
            var notes_title_markup = @"<b>$(Services.I18n.NOTES):</b>\0";
            Pango.Layout section_title_layout;
            Pango.Layout content_layout;
            Cairo.TextExtents title_extents;
            Pango.Rectangle ink_rect, logical_rect;
            int max_section_title_width;

            cairo_context.text_extents (traits_title_markup, out title_extents);
            max_section_title_width = ((int) title_extents.width * Pango.SCALE).clamp (0, 150);

            // TRAITS

            if (chunk.traits.length != 0) {
                section_title_layout = Pango.cairo_create_layout (cairo_context);
                section_title_layout.set_font_description (Pango.FontDescription.from_string (
                    @"$(chunk.parent_document.settings.font_family) $(chunk.parent_document.settings.font_size * POINT_SCALE)" // vala-lint=line-length
                ));
                section_title_layout.set_width (max_section_title_width);
                section_title_layout.set_height ((int) title_extents.height * Pango.SCALE);
                section_title_layout.set_markup (traits_title_markup, -1);
                section_title_layout.set_wrap (Pango.WrapMode.WORD);
                Pango.cairo_show_layout (cairo_context, section_title_layout);

                cairo_context.rel_move_to (max_section_title_width, 0);

                content_layout = Pango.cairo_create_layout (cairo_context);
                content_layout.set_font_description (Pango.FontDescription.from_string (
                    @"$(chunk.parent_document.settings.font_family) $(chunk.parent_document.settings.font_size * POINT_SCALE)" // vala-lint=line-length
                ));
                content_layout.set_width (
                    (int) (
                        (surface_width * Pango.SCALE)
                        - (section_title_layout.get_width () * Pango.SCALE)
                        - ((page_margin * Pango.SCALE) * 2)
                    )
                );
                content_layout.set_height (-1);
                content_layout.set_wrap (Pango.WrapMode.WORD);
                content_layout.set_text (chunk.traits, chunk.traits.length);
                Pango.cairo_show_layout (cairo_context, content_layout);

                content_layout.get_extents (out ink_rect, out logical_rect);
                cairo_context.rel_move_to (
                    - max_section_title_width,
                    (ink_rect.height / Pango.SCALE) +
                        chunk.parent_document.settings.paragraph_spacing.clamp (
                            60, chunk.parent_document.settings.paragraph_spacing
                        )
                );
            }

            // BACKGROUND

            if (chunk.background.length != 0) {
                section_title_layout = Pango.cairo_create_layout (cairo_context);
                section_title_layout.set_font_description (Pango.FontDescription.from_string (
                    @"$(chunk.parent_document.settings.font_family) $(chunk.parent_document.settings.font_size * POINT_SCALE)" // vala-lint=line-length
                ));
                section_title_layout.set_width (max_section_title_width);
                section_title_layout.set_height ((int) title_extents.height * Pango.SCALE);
                section_title_layout.set_markup (background_title_markup, -1);
                section_title_layout.set_wrap (Pango.WrapMode.WORD);
                Pango.cairo_show_layout (cairo_context, section_title_layout);

                cairo_context.rel_move_to (max_section_title_width, 0);

                content_layout = Pango.cairo_create_layout (cairo_context);
                content_layout.set_font_description (Pango.FontDescription.from_string (
                    @"$(chunk.parent_document.settings.font_family) $(chunk.parent_document.settings.font_size * POINT_SCALE)" // vala-lint=line-length
                ));
                content_layout.set_width (
                    (int) (
                        (surface_width * Pango.SCALE)
                        - (section_title_layout.get_width () * Pango.SCALE)
                        - ((page_margin * Pango.SCALE) * 2)
                    )
                );
                content_layout.set_height (-1);
                content_layout.set_wrap (Pango.WrapMode.WORD);
                content_layout.set_text (chunk.background, chunk.background.length);
                Pango.cairo_show_layout (cairo_context, content_layout);

                content_layout.get_extents (out ink_rect, out logical_rect);
                cairo_context.rel_move_to (
                    - max_section_title_width,
                    (ink_rect.height / Pango.SCALE) +
                        chunk.parent_document.settings.paragraph_spacing.clamp (
                            60, chunk.parent_document.settings.paragraph_spacing
                        )
                );
            }

            // NOTES

            if (chunk.notes.length != 0) {
                section_title_layout = Pango.cairo_create_layout (cairo_context);
                section_title_layout.set_font_description (Pango.FontDescription.from_string (
                    @"$(chunk.parent_document.settings.font_family) $(chunk.parent_document.settings.font_size * POINT_SCALE)" // vala-lint=line-length
                ));
                section_title_layout.set_width (max_section_title_width);
                section_title_layout.set_height ((int) title_extents.height * Pango.SCALE);
                section_title_layout.set_markup (notes_title_markup, -1);
                section_title_layout.set_wrap (Pango.WrapMode.WORD);
                Pango.cairo_show_layout (cairo_context, section_title_layout);

                cairo_context.rel_move_to (max_section_title_width, 0);

                content_layout = Pango.cairo_create_layout (cairo_context);
                content_layout.set_font_description (Pango.FontDescription.from_string (
                    @"$(chunk.parent_document.settings.font_family) $(chunk.parent_document.settings.font_size * POINT_SCALE)" // vala-lint=line-length
                ));
                content_layout.set_width (
                    (int) (
                        (surface_width * Pango.SCALE)
                        - (section_title_layout.get_width () * Pango.SCALE)
                        - ((page_margin * Pango.SCALE) * 2)
                    )
                );
                content_layout.set_height (-1);
                content_layout.set_text (chunk.notes, chunk.notes.length);
                Pango.cairo_show_layout (cairo_context, content_layout);
            }

            mark_page_number ();
        }

        private void mark_page_number () {
            cairo_context.save ();
            cairo_context.select_font_face (
                cached_document.settings.font_family,
                Cairo.FontSlant.NORMAL,
                Cairo.FontWeight.NORMAL
            );
            cairo_context.set_font_size (cached_document.settings.font_size * PAGE_NUMBER_SCALE_FACTOR);
            string page_number_text = page_counter.to_string ();
            Cairo.TextExtents page_number_extent;
            cairo_context.text_extents (page_number_text, out page_number_extent);
            cairo_context.move_to (
                (surface_width / 2) - page_number_extent.width,
                surface_height - page_number_extent.height - page_margin
            );
            cairo_context.show_text (page_number_text);
            cairo_context.restore ();
        }

        private void new_page () {
            if (page_counter != 0) {
                cairo_context.show_page ();
                cairo_context.move_to (page_margin, page_margin);
            }

            page_counter ++;
        }

        private Pango.Layout create_page_layout (Models.DocumentChunk chunk) {
            Pango.Layout layout = new Pango.Layout (pango_context);
            int layout_line_spacing = (int) Math.floor (
                (chunk.parent_document.settings.line_spacing * POINT_SCALE * Pango.SCALE)
            );

            layout.set_width ((int) ((surface_width * Pango.SCALE) - (page_margin * Pango.SCALE * 2)));
            layout.set_height ((int) (surface_height * Pango.SCALE - (page_margin * Pango.SCALE * 2)));
            layout.set_font_description (Pango.FontDescription.from_string (
                @"$(chunk.parent_document.settings.font_family) $(chunk.parent_document.settings.font_size * POINT_SCALE)" // vala-lint=line-length
            ));
            layout.set_indent ((int) (chunk.parent_document.settings.paragraph_start_padding * POINT_SCALE * Pango.SCALE)); // vala-lint=line-length
            layout.set_spacing (layout_line_spacing);
            layout.set_ellipsize (Pango.EllipsizeMode.NONE);
            layout.set_wrap (Pango.WrapMode.WORD);
            layout.set_alignment (Pango.Alignment.LEFT);
            layout.set_justify (true);
            layout.context_changed ();

            return layout;
        }
    }
}
