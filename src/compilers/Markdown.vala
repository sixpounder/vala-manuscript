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
    public class MarkdownCompiler : ManuscriptCompiler {
        const string LINE_TERMINATOR = "\n";
        private uint page_counter = 0;
        private FileOutputStream stream { get; set; }

        private string new_page_marker =
            "%s%s========================================================================================================================%s%s".printf ( // vala-lint=line-length
                LINE_TERMINATOR, LINE_TERMINATOR, LINE_TERMINATOR, LINE_TERMINATOR
            );

        internal MarkdownCompiler () {}

        public override async void compile (Manuscript.Models.Document document) throws CompilerError {
            FileIOStream ios;
            try {
                var file = File.new_for_path (filename);
                if (file.query_exists ()) {
                    file.delete ();
                }
                ios = file.create_readwrite (FileCreateFlags.REPLACE_DESTINATION);
            } catch (Error e) {
                set_error (new CompilerError.IO ("Could not create output file: %s", e.message));
                throw get_error ();
            }

            stream = ios.output_stream as FileOutputStream;

            render_default_cover (document);

            var chapters = document.iter_chunks_by_kind (Models.ChunkType.CHAPTER);
            chapters.@foreach ((c) => {
                try {
                    if (c.included) {
                        render_chunk (c);
                    }
                } catch (CompilerError e) {
                    set_error (e);
                }
                return !has_error;
            });

            try {
                stream.close ();
            } catch (Error e) {
                set_error (new CompilerError.IO ("Could not close output stream: %s", e.message));
            }

            if (has_error) {
                throw get_error ();
            }
        }

        private void render_chunk (Models.DocumentChunk chunk) throws CompilerError {
            if (Utils.chunk_kind_supported (chunk.kind)) {
                switch (chunk.kind) {
                    case Manuscript.Models.ChunkType.CHAPTER:
                        render_chapter ((Models.ChapterChunk) chunk);
                        break;
                    case Manuscript.Models.ChunkType.COVER:
                        render_cover ((Models.CoverChunk) chunk);
                        break;
                    case Manuscript.Models.ChunkType.NOTE:
                        render_note ((Models.NoteChunk) chunk);
                        break;
                    case Manuscript.Models.ChunkType.CHARACTER_SHEET:
                        break;
                    default:
                        break;
                }
            }
        }

        private void render_cover (Models.CoverChunk chunk) throws CompilerError {
            try {
                new_page ();
                write ("\n # %s".printf (chunk.parent_document.title.up ()));
            } catch (Error e) {
                throw new CompilerError.IO ("Could not render cover: %s", e.message);
            }
        }

        private void render_default_cover (Models.Document document) throws CompilerError {
            try {
                write ("\n");
                write ("\n# %s".printf (document.title.up ()));
                write ("\n");
                write ("## %s".printf (document.settings.author_name));
                write (LINE_TERMINATOR);
                write (LINE_TERMINATOR);
            } catch (Error e) {
                critical ("%s", e.message);
                throw new CompilerError.IO ("Could not render cover: %s", e.message);
            }
        }

        private void render_chapter (Models.ChapterChunk chunk) throws CompilerError {
            try {
                new_page ();
                chunk.ensure_buffer ();

                write ("### %s%s%s".printf (chunk.title, LINE_TERMINATOR, LINE_TERMINATOR));

                var buffer = ((Models.TextChunk) chunk).buffer;
                Gtk.TextIter cursor;
                buffer.get_start_iter (out cursor);
                var line_word_counter = 0;
                while (!cursor.is_end ()) {
                    if (cursor.starts_word ()) {
                        Gtk.TextIter step = cursor;
                        step.forward_word_end ();
                        string word = buffer.get_text (cursor, step, false);
                        line_word_counter += 1;
                        write (word);
                        if (line_word_counter >= options.max_words_per_line) {
                            write (LINE_TERMINATOR);
                            line_word_counter = 0;
                        }
                        cursor.forward_word_end ();
                    } else {
                        write (cursor.get_char ().to_string ());
                        cursor.forward_char ();
                    }
                }
            } catch (Error e) {
                throw new CompilerError.IO ("Could not render chapter: %s", e.message);
            }
        }

        private void render_note (Models.NoteChunk chunk) throws CompilerError {
            try {
                new_page ();
                chunk.ensure_buffer ();
                var buffer = ((Models.TextChunk) chunk).buffer;
                Gtk.TextIter cursor;
                buffer.get_start_iter (out cursor);

                var line_word_counter = 0;
                while (!cursor.is_end ()) {
                    if (cursor.starts_word ()) {
                        Gtk.TextIter step = cursor;
                        step.forward_word_end ();
                        string word = buffer.get_text (cursor, step, false);
                        line_word_counter += 1;
                        write (word);
                        if (line_word_counter >= options.max_words_per_line) {
                            write (LINE_TERMINATOR);
                            line_word_counter = 0;
                        }
                        cursor.forward_word_end ();
                    } else {
                        write (cursor.get_char ().to_string ());
                        cursor.forward_char ();
                    }
                }
            } catch (Error e) {
                throw new CompilerError.IO ("Could not render note: %s", e.message);
            }
        }

        private void new_page () throws CompilerError {
            if (page_counter != 0) {
                try {
                    write (new_page_marker);
                } catch (Error e) {
                    throw new CompilerError.IO ("New page marker could not be written");
                }
            }

            page_counter ++;
        }

        private void write (string data) throws GLib.IOError {
            size_t bytes_written;
            stream.write_all (data.data, out bytes_written);
            //  debug ("Wrote %s bytes", bytes_written.to_string ());
        }
    }
}
