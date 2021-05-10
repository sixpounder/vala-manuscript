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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Manuscript.Compilers {
    public class PlainTextCompiler : ManuscriptCompiler {
        private uint page_counter = 0;
        private FileOutputStream stream { get; set; }
        private CompilerError? runtime_compile_error { get; set; }

        private uint8[] new_page_marker = "\n\n ============ \n\n".data;
        private uint max_words_per_line = 25;

        internal PlainTextCompiler () {}

        construct {
            runtime_compile_error = null;
            try {
                var file = File.new_for_path (filename);
                var ios = file.create_readwrite (FileCreateFlags.REPLACE_DESTINATION);
                stream = ios.output_stream as FileOutputStream;
            } catch (Error e) {
                runtime_compile_error
                    = new CompilerError.IO ("Could not create output file: %s", runtime_compile_error.message);
            }

        }

        public override async void compile (Manuscript.Models.Document document) throws CompilerError {
            if (runtime_compile_error != null) {
                throw runtime_compile_error;
            }

            var covers = document.iter_chunks_by_type (Models.ChunkType.COVER);
            covers.foreach ((c) => {
                try {
                    render_chunk (c);
                } catch (CompilerError e) {
                    runtime_compile_error = e;
                }
                return runtime_compile_error != null;
            });

            var chapters = document.iter_chunks_by_type (Models.ChunkType.CHAPTER);
            chapters.@foreach ((c) => {
                try {
                    render_chunk (c);
                } catch (CompilerError e) {
                    runtime_compile_error = e;
                }
                return runtime_compile_error != null;
            });

            try {
                stream.close ();
            } catch (Error e) {
                runtime_compile_error = new CompilerError.IO ("Could not close output stream: %s", e.message);
            }

            if (runtime_compile_error != null) {
                throw runtime_compile_error;
            }
        }

        private void render_chunk (Models.DocumentChunk chunk) throws CompilerError {
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

        private void render_cover (Models.CoverChunk chunk) throws CompilerError {
            try {
                new_page ();
                stream.write ("\n *** %s ***".printf (chunk.parent_document.title.up ()).data);
            } catch (Error e) {
                throw new CompilerError.IO ("Could not render cover: %s", e.message);
            }
        }

        private void render_chapter (Models.ChapterChunk chunk) throws CompilerError {
            new_page ();
        }

        private void new_page () throws CompilerError {
            if (page_counter != 0) {
                try {
                    stream.write (new_page_marker);
                } catch (Error e) {
                    throw new CompilerError.IO ("New page marker could not be written");
                }
            }

            page_counter ++;
        }
    }
}
