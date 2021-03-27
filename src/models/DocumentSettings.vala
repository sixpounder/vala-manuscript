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

namespace Manuscript.Models {
    public class DocumentSettings : Object, Json.Serializable, Archivable {
        public string author_name { get; set; }
        public string font_family { get; set; }
        public int64 font_size { get; set; }
        public double paragraph_spacing { get; set; }
        public double paragraph_start_padding { get; set; }
        public bool inline_cover_images { get; set; }

        public DocumentSettings () {
            set_defaults ();
        }

        public DocumentSettings.from_json_object (Json.Object? obj) {
            if (obj != null) {
                if (obj.has_member ("author_name")) {
                    author_name = obj.get_string_member ("author_name");
                } else {
                    author_name = Environment.get_real_name ();
                }

                if (obj.has_member ("font_family")) {
                    font_family = obj.get_string_member ("font_family");
                } else {
                    font_family = Constants.DEFAULT_FONT_FAMILY;
                }

                if (obj.has_member ("font_size")) {
                    font_size = obj.get_int_member ("font_size");
                } else {
                    font_size = Constants.DEFAULT_FONT_SIZE;
                }

                if (obj.has_member ("paragraph_spacing")) {
                    paragraph_spacing = obj.get_int_member ("paragraph_spacing");
                } else {
                    paragraph_spacing = 20;
                }

                if (obj.has_member ("paragraph_start_padding")) {
                    paragraph_start_padding = obj.get_int_member ("paragraph_start_padding");
                } else {
                    paragraph_start_padding = 10;
                }

                if (obj.has_member ("inline_cover_images")) {
                    inline_cover_images = obj.get_boolean_member ("inline_cover_images");
                } else {
                    inline_cover_images = false;
                }
            } else {
                set_defaults ();
            }
        }

        public DocumentSettings.from_data (uint8[] data) throws DocumentError {
            var parser = new Json.Parser ();
            //  SourceFunc callback = from_json.callback;
            try {
                parser.load_from_stream (new MemoryInputStream.from_data (data), null);
            } catch (Error error) {
                throw new DocumentError.PARSE (@"Cannot parse settings data: $(error.message)");
            }

            var obj = parser.get_root ().get_object ();

            if (obj != null) {
                if (obj.has_member ("author_name")) {
                    author_name = obj.get_string_member ("author_name");
                } else {
                    author_name = Environment.get_real_name ();
                }

                if (obj.has_member ("font_family")) {
                    font_family = obj.get_string_member ("font_family");
                } else {
                    font_family = Constants.DEFAULT_FONT_FAMILY;
                }

                if (obj.has_member ("font_size")) {
                    font_size = obj.get_int_member ("font_size");
                } else {
                    font_size = Constants.DEFAULT_FONT_SIZE;
                }

                if (obj.has_member ("paragraph_spacing")) {
                    paragraph_spacing = obj.get_int_member ("paragraph_spacing");
                } else {
                    paragraph_spacing = 20;
                }

                if (obj.has_member ("paragraph_start_padding")) {
                    paragraph_start_padding = obj.get_int_member ("paragraph_start_padding");
                } else {
                    paragraph_start_padding = 10;
                }

                if (obj.has_member ("inline_cover_images")) {
                    inline_cover_images = obj.get_boolean_member ("inline_cover_images");
                } else {
                    inline_cover_images = false;
                }
            } else {
                set_defaults ();
            }
        }

        public void set_defaults () {
            author_name = Environment.get_real_name ();
            paragraph_spacing = 20;
            paragraph_start_padding = 10;
            font_family = Constants.DEFAULT_FONT_FAMILY;
            font_size = Constants.DEFAULT_FONT_SIZE;
            inline_cover_images = false;
        }

        public Json.Object to_json_object () {
            var root = new Json.Object ();
            root.set_string_member ("author_name", author_name);
            root.set_string_member ("font_family", font_family);
            root.set_int_member ("font_size", font_size);
            root.set_double_member ("paragraph_spacing", paragraph_spacing);
            root.set_double_member ("paragraph_start_padding", paragraph_start_padding);
            root.set_boolean_member ("inline_cover_images", inline_cover_images);

            return root;
        }

        public Gee.Collection<ArchivableItem> to_archivable_entries () {
            Json.Generator gen = new Json.Generator ();
            var root = new Json.Node (Json.NodeType.OBJECT);
            root.set_object (to_json_object ());
            gen.set_root (root);
            var c = new Gee.ArrayList<ArchivableItem> ();
            var item = new ArchivableItem ();
            item.name = "settings.json";
            item.group = "";
            item.data = gen.to_data (null).data;

            c.add (item);

            return c;
        }

        public Archivable from_archive_entries (Gee.Collection<ArchivableItem> entries) {
            return this;
        }
    }
}
