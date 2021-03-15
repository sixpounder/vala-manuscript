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
    public class CoverChunk : DocumentChunk {

        public int64 bits_per_sample { get; set; }
        public int64 image_width { get; set; }
        public int64 image_height { get; set; }
        public int64 image_rowstride { get; set; }
        public bool image_has_alpha { get; set; }

        protected string _image_data { get; set; }
        public string image_data {
            get {
                return _image_data;
            }
            set {
                _image_data = value;
                if (_image_data != "") {
                    pixel_buffer = new Gdk.Pixbuf.from_data (
                        _image_data.data,
                        Gdk.Colorspace.RGB,
                        image_has_alpha,
                        (int) bits_per_sample,
                        (int) image_width,
                        (int) image_height,
                        (int) image_rowstride
                    );
                } else {
                    pixel_buffer = null;
                }
            }
        }

        protected Gdk.Pixbuf? _pixel_buffer { get; set; }
        public Gdk.Pixbuf? pixel_buffer {
            get {
                return _pixel_buffer;
            }
            set {
                _pixel_buffer = value;
                _image = new Gtk.Image.from_pixbuf (_pixel_buffer);
            }
        }

        protected Gtk.Image? _image;
        public Gtk.Image? image {
            get {
                return _image;
            }
        }

        public CoverChunk.empty () {
            uuid = GLib.Uuid.string_random ();
            title = _("New cover");
            kind = ChunkType.COVER;
        }

        public override Json.Object to_json_object () {
            var node = base.to_json_object ();

            node.set_string_member ("image_data", image_data);
            node.set_int_member ("image_width", image_width);
            node.set_int_member ("image_height", image_height);
            node.set_int_member ("bits_per_sample", bits_per_sample);
            node.set_int_member ("image_rowstride", image_rowstride);
            node.set_boolean_member ("image_has_alpha", image_has_alpha);

            return node;
        }

        public CoverChunk.from_json_object (Json.Object obj) {
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

            title = obj.get_string_member ("title");

            if (obj.has_member ("index")) {
                index = obj.get_int_member ("index");
            } else {
                index = 0;
            }

            kind = (Models.ChunkType) obj.get_int_member ("chunk_type");

            if (obj.has_member ("alpha")) {
                image_has_alpha = obj.get_boolean_member ("alpha");
            } else {
                image_has_alpha = false;
            }

            if (obj.has_member ("bits_per_sample")) {
                bits_per_sample = obj.get_int_member ("bits_per_sample");
            } else {
                bits_per_sample = 32; // ??
            }

            if (obj.has_member ("width")) {
                image_width = obj.get_int_member ("image_width");
            } else {
                image_width = Manuscript.Constants.A4_WIDHT_IN_POINTS;
            }

            if (obj.has_member ("height")) {
                image_height = obj.get_int_member ("image_height");
            } else {
                image_height = Manuscript.Constants.A4_HEIGHT_IN_POINTS;
            }

            if (obj.has_member ("image_rowstride")) {
                image_rowstride = obj.get_int_member ("image_rowstride");
            } else {
                image_rowstride = image_width; // What am I even doing?
            }

            if (obj.has_member ("image_data")) {
                image_data = obj.get_string_member ("image_data");
            } else {
                image_data = "";
            }
        }
    }

}
