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

namespace Manuscript.Models.Lib {

    const unichar OPEN_TAG_TOKEN = '<';
    const unichar CLOSE_TAG_TOKEN = '>';
    const unichar TAG_ESCAPE_TOKEN = '&';

    public class MarkupParser : Object {
        public virtual signal void parse_end (ulong millis) {
            debug ("Parsing done in %s milliseconds", millis.to_string ());
        }
        private Timer bench_timer;
        private SList<unichar> parse_tokens;
        private SList<Gtk.TextTag> tag_stack;
        private TextBuffer buffer;
        private Gee.HashMap<string, Gtk.TextMark> appended_marks;
        private Gee.HashMap<string, Gtk.TextMark> closing_marks;
        private string? text;
        private int text_index;
        private int buf_index;

        public MarkupParser (TextBuffer buffer) {
            this.buffer = buffer;
        }

        construct {
            this.bench_timer = new Timer ();
            this.text_index = -1;
            this.buf_index = 0;
            this.appended_marks = new Gee.HashMap<string, Gtk.TextMark> ();
            this.closing_marks = new Gee.HashMap<string, Gtk.TextMark> ();
            this.parse_tokens = new SList<unichar> ();
            this.tag_stack = new SList<Gtk.TextTag> ();
        }

        public void parse (string text, bool reset = true) {
            this.bench_timer.start ();
            if (reset) {
                buffer.set_text ("");
            }

            this.text = text;

            while (!is_end ()) {
                unichar ch = next ();
                token (ch);
            }

            // Flush any remaining tokens
            flush_tokens ();

            // Apply tags to buffer

            appended_marks.keys.foreach (key => {
                var mark_open = appended_marks.get (key);
                var mark_close = closing_marks.get (key);

                if (mark_open != null && mark_close != null) {
                    Gtk.TextIter open_iter, close_iter;
                    buffer.get_iter_at_mark (out open_iter, mark_open);
                    buffer.get_iter_at_mark (out close_iter, mark_close);
                    string tag_name = mark_open.get_data ("name");
                    buffer.apply_tag_by_name (tag_name, open_iter, close_iter);
                }

                return true;
            });

            this.bench_timer.stop ();
            ulong micros;
            this.bench_timer.elapsed (out micros);
            this.parse_end (micros / 10);
        }

        private void token (unichar ch) {
            if (ch == OPEN_TAG_TOKEN && peek_behind () != TAG_ESCAPE_TOKEN) {
                flush_tokens ();
                bool is_tag_end = peek () == '/';
                var peek_tokens = forward_until (CLOSE_TAG_TOKEN);
                if (is_tag_end) {
                    // This is a </tag>
                    var last = tag_stack.nth_data (tag_stack.length () - 1);
                    tag_stack.remove (last);
                    mark_at_buffer_position (last.name, false);
                } else {
                    // This is a <tag>
                    var tag = buffer.tag_table.lookup (consume_token_list (ref peek_tokens));
                    if (tag != null) {
                        tag_stack.append (tag);
                        mark_at_buffer_position (tag.name, true);
                    }
                }
            } else {
                parse_tokens.append (ch);
                buf_index ++;
            }
        }

        private uint depth {
            get {
                return tag_stack.length ();
            }
        }

        /** Peeks at the next token, without advancing any counter */
        private unichar? peek () {
            if (text_index < text.length - 2) {
                return text[text_index + 1];
            } else {
                return null;
            }
        }

        /** Peeks at the previous token, without rewinding any counter */
        private unichar? peek_behind () {
            if (text_index > 0) {
                return text[text_index - 1];
            } else {
                return null;
            }
        }

        private bool is_end () {
            return text_index >= text.length - 1;
        }

        /** Moves the parser to the next token in the text to parse */
        private unichar next () {
            text_index ++;
            unichar c;
            text.get_next_char (ref text_index, out c);
            return c;
        }

        private SList<unichar> forward_until (unichar stop_mark) {
            var peek_tokens = new SList<unichar> ();
            unichar peek_char = next (); 
            while (peek_char != CLOSE_TAG_TOKEN) {
                peek_tokens.append (peek_char);
                peek_char = next ();
            }

            return peek_tokens;
        }

        /** Flushes parsed tokens to the TextBuffer */
        private void flush_tokens () {
            Gtk.TextIter cursor;
            buffer.get_iter_at_offset (out cursor, buf_index);
            string tokens = consume_token_list (ref parse_tokens);
            buffer.insert (ref cursor, tokens, tokens.length);
        }

        /**
         * Consumes `list` and creates a plain string from it
         */
        private string consume_token_list (ref SList<unichar> list) {
            StringBuilder acc = new StringBuilder.sized (list.length ());
            list.@foreach (c => {
                acc.append_unichar (c);
            });

            list = new SList<unichar> ();

            string utf8s = (string) acc.str.to_utf8 ();
            if (!utf8s.validate ()) {
                warning ("String does not validate as utf8");
            }

            return utf8s;
        }

        private Gtk.TextIter iter_at_buffer_position () {
            Gtk.TextIter cursor;
            buffer.get_iter_at_offset (out cursor, buf_index);
            return cursor;
        }

        private void mark_at_buffer_position (string? name, bool open = true) {
            var iter = iter_at_buffer_position ();
            var key = @"$(name)-$(depth)-$(open == true ? "open" : "close")";
            var mark = buffer.create_mark (key, iter, open);
            mark.set_data ("name", name);
            mark.set_data ("open", open);
            mark.set_data ("close", !open);
            if (open) {
                appended_marks.set (key, mark);
            } else {
                closing_marks.set (key, mark);
            }
        }
    }
}
