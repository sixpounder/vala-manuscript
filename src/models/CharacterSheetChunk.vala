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
    public class CharacterSheetChunk : DocumentChunk {
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

        public override Json.Object to_json_object () {
            var node = base.to_json_object ();
            node.set_string_member ("name", name);
            node.set_string_member ("background", background);
            node.set_string_member ("traits", traits);
            node.set_string_member ("notes", notes);
            return node;
        }

        public CharacterSheetChunk.from_json_object (Json.Object obj) {
            assert (obj != null);
            if (obj.has_member ("uuid")) {
                uuid = obj.get_string_member ("uuid");
            } else {
                info ("Chunk has no uuid, generating one now");
                uuid = GLib.Uuid.string_random ();
            }

            if (obj.has_member ("locked")) {
                locked = obj.get_boolean_member ("locked");
            } else {
                locked = false;
            }

            if (obj.has_member ("notes")) {
                notes = obj.get_string_member ("notes");
            } else {
                notes = null;
            }

            title = obj.get_string_member ("title");

            if (obj.has_member ("index")) {
                index = obj.get_int_member ("index");
            } else {
                index = 0;
            }

            kind = (Models.ChunkType) obj.get_int_member ("chunk_type");

            if (obj.has_member ("name")) {
                name = obj.get_string_member ("name");
            } else {
                name = "";
            }

            if (obj.has_member ("background")) {
                background = obj.get_string_member ("background");
            } else {
                background = "";
            }

            if (obj.has_member ("traits")) {
                traits = obj.get_string_member ("traits");
            } else {
                traits = "";
            }

            if (obj.has_member ("notes")) {
                notes = obj.get_string_member ("notes");
            } else {
                notes = "";
            }
        }
    }
}
