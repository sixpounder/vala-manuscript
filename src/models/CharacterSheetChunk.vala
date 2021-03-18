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
    public class CharacterSheetChunk : DocumentChunkBase {
        public string name { get; set; }
        public string background { get; set; }
        public string traits { get; set; }
        public string notes { get; set; }

        public CharacterSheetChunk.empty () {
            uuid = GLib.Uuid.string_random ();
            title = _("New character sheet");
            kind = ChunkType.CHARACTER_SHEET;
            name = "";
            background = "";
            traits = "";
            notes = "";
        }

        public Json.Object to_json_object () {
            var node = base.to_json_object ();
            node.set_string_member ("name", name);
            node.set_string_member ("background", background);
            node.set_string_member ("traits", traits);
            node.set_string_member ("notes", notes);
            return node;
        }

        public static CharacterSheetChunk from_json_object (Json.Object obj, Document document) {
            CharacterSheetChunk self = (CharacterSheetChunk) DocumentChunk.from_json_object (obj, document);

            if (obj.has_member ("name")) {
                self.name = obj.get_string_member ("name");
            } else {
                self.name = "";
            }

            if (obj.has_member ("background")) {
                self.background = obj.get_string_member ("background");
            } else {
                self.background = "";
            }

            if (obj.has_member ("traits")) {
                self.traits = obj.get_string_member ("traits");
            } else {
                self.traits = "";
            }

            if (obj.has_member ("notes")) {
                self.notes = obj.get_string_member ("notes");
            } else {
                self.notes = "";
            }

            return self;
        }
    }
}
