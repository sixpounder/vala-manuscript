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

namespace Manuscript.Utils.Streams {
    public uint8[] read_until (InputStream stream, uint8 marker = '\0') throws Error {
        return read_until_sequence (stream, { marker });
    }

    public uint8[] read_until_sequence (InputStream stream, uint8[] pattern = { '\0' }) throws Error {
        Gee.ArrayList<uint8> pattern_stack = new Gee.ArrayList<uint8> ();

        MemoryOutputStream content_buffer = new MemoryOutputStream.resizable ();
        uint8 buffer[1];
        bool marker_reached = false;
        while (true) {
            try {
                stream.read (buffer);
            } catch (IOError io_error) {
                warning ("read_until_sequence aborting for IOError (stream ended?)");
                break;
            }

            pattern_stack.add (buffer[0]);

            if (pattern_stack.size > pattern.length) {
                pattern_stack.remove_at (0);

                var iterator = pattern_stack.bidir_list_iterator ();
                while (iterator.next ()) {
                    marker_reached = iterator.@get () == pattern[iterator.index ()];
                    if (!marker_reached) break;
                }
            } else {
                marker_reached = false;
            }

            if (marker_reached || stream.is_closed ()) {
                break;
            } else {
                content_buffer.write (buffer);
            }
        }

        content_buffer.close ();
        var data = content_buffer.steal_data ();
        data.length = (int) content_buffer.get_data_size ();

        return data;
    }
}
