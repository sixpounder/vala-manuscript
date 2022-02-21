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

namespace Manuscript.Models {
    public class FootNote : Models.TextChunkArtifact {

        public override string name {
            get {
                return "foot_note";
            }
        }

        public Gtk.TextBuffer content_buffer;

        public FootNote (Models.TextChunk parent_chunk, int start_offset, int end_offset = -1) {
            Object (
                parent_chunk: parent_chunk,
                start_iter_offset: start_offset,
                end_iter_offset: end_offset
            );
        }

        construct {
            content_buffer = new Gtk.TextBuffer (new Manuscript.Models.XManuscriptTagTable ());
        }
    }
}
