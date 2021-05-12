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
    public class Utils {
        public static bool chunk_kind_supported (Models.ChunkType kind) {
            switch (kind) {
                case Models.ChunkType.CHAPTER:
#if CHUNK_CHAPTER
                    return true;
#else
                    return false;
#endif
                case Models.ChunkType.CHARACTER_SHEET:
#if CHUNK_CHARACTER_SHEET
                    return true;
#else
                    return false;
#endif
                case Models.ChunkType.COVER:
#if CHUNK_COVER
                    return true;
#else
                    return false;
#endif
                case Models.ChunkType.NOTE:
#if CHUNK_NOTE
                    return true;
#else
                    return false;
#endif
                default:
                    return false;
            }
        }

        public static string? tag_name_to_markup (string tag_name) {
            switch (tag_name) {
                case "bold":
                    return "b";
                case "italic":
                    return "i";
                case "underline":
                    return "u";
                default:
                    return null;
            }
        }
    }
}
