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
    public class FootNote : Object {
        public FootNote (Models.TextChunk parent_chunk, int start_offset, int end_offset = -1) {
            Object (
                parent_chunk: parent_chunk,
                start_iter_offset: start_offset,
                end_iter_offset: end_offset
            );
        }

        // The chunk this note belongs to
        public weak Models.TextChunk parent_chunk { get; construct; }

        // The start iter in the parent chunk's buffer at which this note begins
        public int start_iter_offset { get; construct set; }

        // The start iter in the parent chunk's buffer at which this note ends. Can be null,
        // indicating that the note belongs to a specific cursor point and not a text section
        public int end_iter_offset { get; construct set; }

        // The start iter in the parent chunk's buffer at which this note begins
        public Gtk.TextIter? start_iter {
            get {
                if (parent_chunk != null) {
                    Gtk.TextIter out_iter;
                    parent_chunk.buffer.get_iter_at_offset (out out_iter, start_iter_offset);
                    return out_iter;
                } else {
                    return null;
                }
            }
        }

        // The start iter in the parent chunk's buffer at which this note ends. Can be null,
        // indicating that the note belongs to a specific cursor point and not a text section
        public Gtk.TextIter? end_iter {
            get {
                if (parent_chunk != null && end_iter_offset != -1) {
                    Gtk.TextIter out_iter;
                    parent_chunk.buffer.get_iter_at_offset (out out_iter, end_iter_offset);
                    return out_iter;
                } else {
                    return null;
                }
            }
        }

        public bool spans_text {
            get {
                return start_iter_offset != -1 && end_iter_offset != -1;
            }
        }
    }
}
