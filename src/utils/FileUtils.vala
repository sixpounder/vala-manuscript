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

namespace Manuscript {
    public class FileUtils : Object {
        public static File new_temp_file (string buffer) throws GLib.Error {
            File file = File.new_for_path (
                Path.build_filename (
                    Environment.get_user_cache_dir (),
                    Constants.APP_ID,
                    @"$(GLib.Uuid.string_random ())$(Constants.DEFAULT_FILE_EXT)"
                )
            );

            FileOutputStream os = file.create (FileCreateFlags.PRIVATE);
            os.write (buffer.data);
            return file;
        }

        public static string? get_extensionless (string path) {
            var ext = FileUtils.get_extension (path);
            return ext == "" ? path : path.substring (0, path.index_of (ext));
        }

        public static string? get_extension (string path) {
            string basename = Path.get_basename (path);
            var index_of_point = basename.index_of (".");
            if (index_of_point != -1) {
                return basename.substring (index_of_point);
            } else {
                return "";
            }
        }

        public static string? read (string path) throws Models.DocumentError {
            File file = File.new_for_path (path);
            if (file.query_exists ()) {
                try {
                    uint8[] contents;
                    string etag_out;

                    file.load_contents (null, out contents, out etag_out);

                    return (string) contents;
                } catch (Error e) {
                    throw new Models.DocumentError.READ (e.message);
                }
            } else {
                throw new Models.DocumentError.NOT_FOUND ("File not found");
            }
        }

        public static string? read_file (File file) throws Models.DocumentError {
            return FileUtils.read (file.get_path ());
        }

        public static async string? read_async (File file) throws GLib.Error {
            var text = new StringBuilder ();
            if (!file.query_exists ()) {
                throw new FileError.ACCES ("E_NOT_FOUND");
            } else {
                try {
                  var dis = new DataInputStream (file.read ());
                  string line = null;
                  while ((line = yield dis.read_line_async (Priority.DEFAULT)) != null) {
                    if (text.len != 0) {
                        text.append_c ('\n');
                    }
                    text.append (line);
                  }
                  return text.str;
                } catch (Error e) {
                    warning ("Cannot read \"%s\": %s", file.get_basename (), e.message);
                    throw e;
                }
            }
        }

        public static void save_buffer (Gtk.TextBuffer buffer, string path) throws Error {
            FileUtils.save (buffer.text, path);
        }

        public static long save (string text, string path) throws Error {
            File file = File.new_for_path (path);

            FileOutputStream @os = file.query_exists ()
                ? file.replace (null, false, FileCreateFlags.REPLACE_DESTINATION, null)
                : file.create (FileCreateFlags.NONE);

            var dos = new DataOutputStream (
                new BufferedOutputStream.sized (@os, text.length)
            );

            uint8[] data = text.data;
            long written = 0;
            while (written < data.length) {
                // sum of the bytes of 'text' that already have been written to the stream
                written += dos.write (data[written:data.length]);
            }

            return written;
        }
    }
}
