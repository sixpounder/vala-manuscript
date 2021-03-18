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
    public class CoverChunk : DocumentChunkBase {

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

        public Json.Object to_json_object () {
            var node = base.to_json_object ();

            if (_pixel_buffer != null) {
                if (parent_document.settings.inline_cover_images) {
                    var image_data = _pixel_buffer.read_pixel_bytes ().get_data ();
                    var image_data_encoded = GLib.Base64.encode (image_data);
                    node.set_string_member ("image_data_base64", image_data_encoded);
                } else {
                    node.set_string_member ("image_source_file", "");
                }
            }

            node.set_boolean_member ("paint_title", paint_title);
            node.set_boolean_member ("paint_author_name", paint_author_name);

            return node;
        }

        public static CoverChunk from_json_object (Json.Object obj, Document document) {
            CoverChunk self = (CoverChunk) DocumentChunk.from_json_object (obj, document);

            if (obj.has_member ("paint_title")) {
                self.paint_title = obj.get_boolean_member ("paint_title");
            } else {
                self.paint_title = false;
            }

            if (obj.has_member ("paint_author_name")) {
                self.paint_author_name = obj.get_boolean_member ("paint_author_name");
            } else {
                self.paint_author_name = false;
            }

            InputStream stream = null;
            if (obj.has_member ("image_data_base64")) {
                //  var arr = obj.get_array_member ("image_data");
                //  var image_data = new uint8[arr.get_length ()];

                //  arr.foreach_element ((a, i, el) => {
                //      image_data[i] = (uint8) el.get_int ();
                //  });
                string raw_data = obj.get_string_member ("image_data_base64");
                uchar[] decoded_data = GLib.Base64.decode (raw_data);
                stream = new MemoryInputStream.from_data (decoded_data, GLib.free);

                if (stream != null) {
                    self.load_cover_from_stream.begin (stream, (obj, res) => {
                        try {
                            stream.close ();
                        } catch (IOError err) {
                            warning (@"Memory stream containing cover data was NOT closed: $(err.message)");
                        }
                    });
                }
            } else if (obj.has_member ("image_source_file")) {
                try {
                    File file = File.new_for_path (obj.get_string_member ("image_source_file"));
                    IOStream ios = file.create_readwrite (FileCreateFlags.NONE);
                    stream = ios.input_stream;
    
                    if (stream != null) {
                        self.load_cover_from_stream.begin (stream, (obj, res) => {
                            try {
                                stream.close ();
                            } catch (IOError err) {
                                warning (@"Memory stream containing cover data was NOT closed: $(err.message)");
                            }
                        });
                    }
                } catch (Error e) {
                    critical (@"Cannot load image from source file: $(e.message)");
                    self.pixel_buffer = null;
                }
            } else {
                self.pixel_buffer = null;
            }

            return self;
        }
    }
}
