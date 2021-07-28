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
    public class TextBuffer : Gtk.SourceBuffer {
        private Gdk.Atom serialize_atom;
        private Gdk.Atom deserialize_atom;
        public TextBuffer () {
            Object (
                tag_table: new XManuscriptTagTable ()
            );
        }

        construct {
            serialize_atom = register_serialize_tagset ("x-manuscript");
            deserialize_atom = register_deserialize_tagset ("x-manuscript");
        }

        public Gdk.Atom get_manuscript_serialize_format () {
            return serialize_atom;
        }

        public Gdk.Atom get_manuscript_deserialize_format () {
            return deserialize_atom;
        }

        public uint8[] serialize_manuscript () {
            //  var atom = get_manuscript_serialize_format ();
            Gtk.TextIter start, end, cursor;
            get_start_iter (out start);
            get_end_iter (out end);
            cursor = start;

            while (!cursor.is_end ()) {
                var possible_anchor = cursor.get_child_anchor ();
                if (possible_anchor != null) {
                    this.delete (ref cursor, ref cursor);
                }
                cursor.forward_char ();
            }

            /**
             *   ___         ___  
             *  (o o)       (o o) 
             * (  V  ) WTF (  V  )
             * --m-m---------m-m--
             *
             * - serialize method goes full recursion if there are child anchors in the buffer
             * - if the user has searched anything, an __anonymous__ Gtk.TextTag is applied to search results,
             *   it gets serialized and fucks shit up when the buffer is loaded again
             * - AND THIS THING IS REMOVE FROM GTK4. FU**.
             */
            //  return serialize (this, atom, start, end);

            return serialize_x_manuscript (start, end);
        }

        public bool deserialize_manuscript (uint8[] raw_content) throws Error {
            Gtk.TextIter cursor;
            get_start_iter (out cursor);
            StringBuilder buffer = new StringBuilder.sized (raw_content.length);
            buffer.append ((string) raw_content);
            string content = buffer.str;

            Gee.ArrayList<Gtk.TextTag> tag_stack = new Gee.ArrayList<Gtk.TextTag> ();
            var i = 0;

            while (i < raw_content.length) {
                this.insert (ref cursor, content.substring (i, 1), 1);
                i ++;
            }

            return true;
        }

        private uint8[] serialize_x_manuscript (Gtk.TextIter start, Gtk.TextIter end) {
            StringBuilder buffer = new StringBuilder ();
            Gee.ArrayList<Gtk.TextTag> tag_stack = new Gee.ArrayList<Gtk.TextTag> ();

            Gtk.TextIter cursor;
            get_start_iter (out cursor);

            while (!cursor.is_end ()) {
                if (cursor.starts_tag (null)) {
                    cursor.get_toggled_tags (true).@foreach (i => {
                        // Only serialize non-anonymous tags, and only tags that can be found in this
                        // buffer's tag table
                        if (i.name != null && tag_table.lookup (i.name) != null) {
                            tag_stack.add (i);
                            buffer.append (open_tag_str (i));
                        }
                    });
                }
                
                if (cursor.ends_tag (null)) {
                    //  debug ("%i %s", tag_stack.size, tag_stack.last ().name);
                    var closed_tags = cursor.get_toggled_tags (false);
                    debug ("Number of closed tags at this iter: %u", closed_tags.length ());
                    while (
                        closed_tags.length () != 0
                    ) {
                        var len = closed_tags.length ();
                        var closed_tag = closed_tags.nth_data (len - 1);

                        buffer.append (close_tag_str (tag_stack.remove_at (tag_stack.size - 1)));
                        closed_tags.remove (closed_tag);
                    }
                }
                // Append the character verbatim
                buffer.append_unichar (cursor.get_char ());
                cursor.forward_char ();
            }
            
            return buffer.data;
        }

        //  public void scan_debug () {
        //      var i = 0;
        //      Gtk.TextIter cursor;
        //      get_start_iter (out cursor);
        //      while (!cursor.is_end ()) {
        //          debug ("Iter: %i", i);
        //          debug (@"Char: $(cursor.get_char ())");
        //          if (cursor.starts_tag (null)) {
        //              cursor.get_toggled_tags (true).@foreach (i => {
        //                  debug ("Open tag %s", i.name);
        //              });
        //              //  debug (@"Start tag: $(debug_slist (cursor.get_toggled_tags (true)))");
        //          } else if (cursor.ends_tag (null)) {
        //              cursor.get_toggled_tags (false).@foreach (i => {
        //                  debug ("Close tag %s", i.name);
        //              });
        //              //  debug (@"Start tag: $(debug_slist (cursor.get_toggled_tags (false)))");
        //          }
        //          cursor.forward_char ();
        //          i += 1;
        //      }
        //  }
    }

    private string open_tag_str (Gtk.TextTag tag) {
        return @"<Tag name=\"$(tag.name)\">";
    }

    private string close_tag_str (Gtk.TextTag tag) {
        return @"</Tag>";
    }
}
