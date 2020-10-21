/*
 * Copyright 2020 Andrea Coronese <sixpounder@protonmail.com>
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

namespace Manuscript.Models {
    public class DocumentSettings : Object, Json.Serializable {
        public string font { get; set; }
        public double paragraph_spacing { get; set; }
        public double paragraph_start_padding { get; set; }

        public DocumentSettings () {
            set_defaults ();
        }

        public DocumentSettings.from_json_object (Json.Object? obj) {
            if (obj != null) {
                font = obj.get_string_member ("font");
                paragraph_spacing = obj.get_double_member ("paragraph_spacing");
                paragraph_start_padding = obj.get_double_member ("paragraph_start_padding");
            } else {
                set_defaults ();
            }
        }

        public void set_defaults () {
            paragraph_spacing = 20;
            paragraph_start_padding = 10;
            font = Constants.DEFAULT_FONT;
        }

        public Json.Object to_json_object () {
            var root = new Json.Object ();
            root.set_string_member ("font", font);
            root.set_double_member ("paragraph_spacing", paragraph_spacing);
            root.set_double_member ("paragraph_start_padding", paragraph_start_padding);

            return root;
        }
    }
}
