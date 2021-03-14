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
    public class CoverEditor : Gtk.Box, Protocols.ChunkEditor {
        public weak Models.CoverChunk chunk { get; construct; }
        public weak Manuscript.Window parent_window { get; construct; }

        public CoverEditor (Manuscript.Window parent_window, Models.CoverChunk chunk) {
            Object (
                parent_window: parent_window,
                chunk: chunk
            );
        }

        construct {
            assert (chunk.kind == Manuscript.Models.ChunkType.COVER);
        }
    }
}
