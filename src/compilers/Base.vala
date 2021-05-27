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
    public errordomain CompilerError {
        IO,
        FORMAL
    }

    public enum PaperSize {
        A3,
        A4,
        A5,
        A6
    }

    public void paper_size_in_points (PaperSize size, out double width, out double height) {
        switch (size) {
            case PaperSize.A4:
            default:
                width = Constants.A4_WIDHT_IN_POINTS;
                height = Constants.A4_HEIGHT_IN_POINTS;
                break;
        }
    }

    public abstract class ManuscriptCompiler : Object {
        public string filename { get; set; }
        public CompilerOptions options { get; private set; }
        public CompilerError? runtime_compile_error { get; protected set; }

        construct {
            options = new CompilerOptions ();
        }

        public bool has_error {
            get {
                return runtime_compile_error != null;
            }
        }

        public CompilerError? get_error () {
            return runtime_compile_error;
        }

        public void set_error (CompilerError? e = null) {
            runtime_compile_error = e;
        }

        public static ManuscriptCompiler for_format (Manuscript.Models.ExportFormat format) {
            switch (format) {
                case Manuscript.Models.ExportFormat.PDF:
                    return new PDFCompiler ();
                case Manuscript.Models.ExportFormat.MARKDOWN:
                    return new MarkdownCompiler ();
                case Manuscript.Models.ExportFormat.PLAIN:
                    return new PlainTextCompiler ();
                default:
                    assert_not_reached ();
            }
        }

        public abstract async void compile (Manuscript.Models.Document document) throws CompilerError;
    }

    public class CompilerOptions : Object {
        public PaperSize page_size { get; set; }
        public uint max_words_per_line { get; set; }
        public Models.PageMargin page_margin { get; set; }

        construct {
            page_size = PaperSize.A4;
            max_words_per_line = 25;
            page_margin = Models.PageMargin.MEDIUM;
        }
    }
}
