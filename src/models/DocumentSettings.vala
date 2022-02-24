/*
 * Copyright 2022 Andrea Coronese <sixpounder@protonmail.com>
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
    public enum PageMargin {
        SMALL,
        MEDIUM,
        LARGE
    }

    public double page_margin_get_value (PageMargin source) {
        switch (source) {
            case PageMargin.SMALL:
                return 40;
            case PageMargin.MEDIUM:
                return 70;
            case PageMargin.LARGE:
                return 100;
            default:
                return 70;
        }
    }

    public PageMargin value_get_page_margin (double source) {
        if (source == 40) {
            return PageMargin.SMALL;
        } else if (source == 70) {
            return PageMargin.MEDIUM;
        } else if (source == 100) {
            return PageMargin.LARGE;
        } else {
            return PageMargin.MEDIUM;
        }
    }

    public class DocumentSettings : Object, Json.Serializable, Archivable {
        public string author_name { get; set; }
        public string font_family { get; set; }
        public int64 font_size { get; set; }
        public double line_spacing { get; set; }
        public double paragraph_start_padding { get; set; }
        public double paragraph_spacing { get; set; }
        public PageMargin page_margin { get; set; }

        public DocumentSettings () {
            set_defaults ();
        }

        public DocumentSettings.from_json_object (Json.Object? obj) {
            DocumentSettings.populate_from_json_object (this, obj);
        }

        public DocumentSettings.from_data (uint8[] data) throws DocumentError {
            var parser = new Json.Parser ();
            try {
                parser.load_from_stream (new MemoryInputStream.from_data (data), null);
            } catch (Error error) {
                throw new DocumentError.PARSE (@"Cannot parse settings data: $(error.message)");
            }

            var obj = parser.get_root ().get_object ();

            DocumentSettings.populate_from_json_object (this, obj);
        }

        private static void populate_from_json_object (DocumentSettings target, Json.Object? obj) {
            if (obj != null) {
                if (obj.has_member ("author_name")) {
                    target.author_name = obj.get_string_member ("author_name");
                } else {
                    target.author_name = Environment.get_real_name ();
                }

                if (obj.has_member ("font_family")) {
                    target.font_family = obj.get_string_member ("font_family");
                } else {
                    target.font_family = Constants.DEFAULT_FONT_FAMILY;
                }

                if (obj.has_member ("font_size")) {
                    target.font_size = obj.get_int_member ("font_size");
                } else {
                    target.font_size = Constants.DEFAULT_FONT_SIZE;
                }

                if (obj.has_member ("line_spacing")) {
                    target.line_spacing = obj.get_double_member ("line_spacing");
                } else {
                    target.line_spacing = Constants.DEFAULT_LINE_SPACING;
                }

                if (obj.has_member ("paragraph_spacing")) {
                    target.paragraph_spacing = obj.get_double_member ("paragraph_spacing");
                } else {
                    target.paragraph_spacing = Constants.DEFAULT_PARAGRAPH_SPACING;
                }

                if (obj.has_member ("paragraph_start_padding")) {
                    target.paragraph_start_padding = obj.get_double_member ("paragraph_start_padding");
                } else {
                    target.paragraph_start_padding = Constants.DEFAULT_PARAGRAPH_INITIAL_PADDING;
                }

                if (obj.has_member ("page_margin")) {
                    target.page_margin = value_get_page_margin (obj.get_double_member ("page_margin"));
                } else {
                    target.page_margin = PageMargin.MEDIUM;
                }
            } else {
                target.set_defaults ();
            }
        }

        public void set_defaults () {
            author_name = Environment.get_real_name ();
            line_spacing = 2;
            paragraph_spacing = 20;
            paragraph_start_padding = 10;
            font_family = Constants.DEFAULT_FONT_FAMILY;
            font_size = Constants.DEFAULT_FONT_SIZE;
            page_margin = PageMargin.MEDIUM;
        }

        public Json.Object to_json_object () {
            var root = new Json.Object ();
            root.set_string_member ("author_name", author_name);
            root.set_string_member ("font_family", font_family);
            root.set_int_member ("font_size", font_size);
            root.set_double_member ("line_spacing", line_spacing);
            root.set_double_member ("paragraph_spacing", paragraph_spacing);
            root.set_double_member ("paragraph_start_padding", paragraph_start_padding);
            root.set_double_member ("page_margin", page_margin_get_value (page_margin));

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
    }
}
