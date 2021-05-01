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
    public class CoverChunk : DocumentChunk, Archivable {

        public GLib.Error load_error { get; private set; }

        public signal void image_changed ();

        public bool paint_title { get; set; }
        public bool paint_author_name { get; set; }
        public File? image_source_file { get; protected set; }

        protected Gdk.Pixbuf? _pixel_buffer;
        public Gdk.Pixbuf? pixel_buffer {
            get {
                if (_pixel_buffer == null) {
                    load_error = null;
                    if (image_source_file != null) {
                        load_cover_from_file.begin (image_source_file.get_path ());
                    }
                }

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

        public async void load_cover_from_file (string file_name) {
            try {
                load_error = null;
                image_source_file = File.new_for_path (file_name);
                FileIOStream stream = yield image_source_file.open_readwrite_async (GLib.Priority.DEFAULT, null);
                if (stream != null) {
                    pixel_buffer = yield new Gdk.Pixbuf.from_stream_async ((InputStream) stream.input_stream);
                    debug (@"Image length: $(pixel_buffer.read_pixel_bytes ().length) bytes");
                }
            } catch (GLib.Error e) {
                warning (e.message);
                load_error = e;
            }
        }

        public async Gdk.Pixbuf? load_cover_from_stream (InputStream input_stream) {
            try {
                load_error = null;
                pixel_buffer = yield new Gdk.Pixbuf.from_stream_async (input_stream);
                debug (@"Pixel buffer from image with length $(pixel_buffer.read_pixel_bytes ().length) bytes");
                return pixel_buffer;
            } catch (GLib.Error e) {
                warning (@"Could not load cover image buffer: $(e.message)");
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

            node.set_boolean_member ("paint_title", paint_title);
            node.set_boolean_member ("paint_author_name", paint_author_name);

            return node;
        }

        public static CoverChunk from_json_object (Json.Object obj, Document document) {
            CoverChunk self = (CoverChunk) DocumentChunk.new_from_json_object (obj, document);

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

            return self;
        }

        public override Gee.Collection<ArchivableItem> to_archivable_entries () {
            Json.Generator gen = new Json.Generator ();
            var root = new Json.Node (Json.NodeType.OBJECT);
            root.set_object (to_json_object ());
            gen.set_root (root);

            var c = new Gee.ArrayList<ArchivableItem> ();
            var item = new ArchivableItem ();
            item.name = @"$uuid.json";
            item.group = kind.to_string ();
            item.data = gen.to_data (null).data;
            c.add (item);

            if (_pixel_buffer != null) {
                try {
                    var image_file = new ArchivableItem ();
                    image_file.name = @"$uuid.png";
                    uint8[] image_data;
                    _pixel_buffer.save_to_buffer (out image_data, "png");
                    image_file.data = image_data;
                    image_file.group = "Resource";
                    c.add (image_file);
                } catch (Error e) {
                    warning (e.message);
                }
            }

            return c;
        }
    }
}
