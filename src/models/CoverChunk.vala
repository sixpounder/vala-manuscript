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

        public GLib.Error load_error { get; private set; }

        public signal void image_changed ();

        public bool paint_title { get; set; }
        public bool paint_author_name { get; set; }

        protected Gdk.Pixbuf? _pixel_buffer;
        public Gdk.Pixbuf? pixel_buffer {
            get {
                return _pixel_buffer;
            }
            set {
                _pixel_buffer = value;
                image_changed ();
            }
        }

        public CoverChunk.empty () {
            uuid = GLib.Uuid.string_random ();
            title = _("New cover");
            kind = ChunkType.COVER;
            paint_title = false;
            paint_author_name = false;
        }

        public void load_cover_from_file (string file_name) {
            load_error = null;
            try {
                pixel_buffer = new Gdk.Pixbuf.from_file (file_name);
            } catch (GLib.Error e) {
                warning (e.message);
                load_error = e;
            }
        }

        public async Gdk.Pixbuf? load_cover_from_stream (InputStream input_stream) {
            load_error = null;
            try {
                pixel_buffer = yield new Gdk.Pixbuf.from_stream_async (input_stream);
                debug (@"Image length: $(pixel_buffer.read_pixel_bytes ().length) bytes");
                return pixel_buffer;
            } catch (GLib.Error e) {
                warning (e.message);
                load_error = e;
                return null;
            }
        }

        public bool has_image {
            get {
                return pixel_buffer != null;
            }
        }

        public bool image_is_valid {
            get {
                return has_image && pixel_buffer.read_pixel_bytes () != null;
            }
        }

        public override Json.Object to_json_object () {
            var node = base.to_json_object ();

            if (_pixel_buffer != null) {
                var image_data = _pixel_buffer.read_pixel_bytes ().get_data ();
                var image_data_array = new Json.Array.sized (image_data.length);
                foreach (uint8 el in image_data) {
                    image_data_array.add_int_element (el);
                }
                node.set_array_member ("image_data", image_data_array);
            }

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

            if (obj.has_member ("paint_title")) {
                paint_title = obj.get_boolean_member ("paint_title");
            } else {
                paint_title = false;
            }

            if (obj.has_member ("paint_author_name")) {
                paint_author_name = obj.get_boolean_member ("paint_author_name");
            } else {
                paint_author_name = false;
            }

            if (obj.has_member ("image_data")) {
                var arr = obj.get_array_member ("image_data");
                var image_data = new uint8[arr.get_length ()];

                arr.foreach_element ((a, i, el) => {
                    image_data[i] = (uint8) el.get_int ();
                });

                var stream = new MemoryInputStream.from_data (image_data, GLib.free);
                load_cover_from_stream.begin (stream, (obj, res) => {
                    try {
                        stream.close ();
                    } catch (IOError err) {
                        warning (@"Memory stream containing cover data was NOT closed: $(err.message)");
                    }
                });
            } else {
                pixel_buffer = null;
            }
        }
    }
}
