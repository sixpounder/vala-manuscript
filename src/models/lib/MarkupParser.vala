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

    public class MarkupParser {
        private Timer bench_timer;
        private SList<unichar> parse_tokens;
        private SList<Gtk.TextTag> tag_stack;
        private TextBuffer buffer;
        private string? text;
        private long text_index;
        private int buf_index;

        public MarkupParser (TextBuffer buffer) {
            this.bench_timer = new Timer ();
            this.buffer = buffer;
            this.text_index = -1;
            this.buf_index = 0;
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
            this.bench_timer.stop ();
            ulong millis;
            this.bench_timer.elapsed (out millis);
            debug ("Parsed text in %s milliseconds", (millis / 10).to_string ());
        }

        private void token (unichar ch) {
            if (ch == OPEN_TAG_TOKEN) {
                flush_tokens ();
                bool is_tag_end = peek () == '/';
                if (is_tag_end) {
                    // This is a </tag>
                    forward_until (CLOSE_TAG_TOKEN);
                    var last = tag_stack.nth_data (tag_stack.length () - 1);
                    tag_stack.remove (last);
                } else {
                    // This is a <tag>
                    var peek_tokens = forward_until (CLOSE_TAG_TOKEN);
                    var tag = buffer.tag_table.lookup (list_to_str (ref peek_tokens));
                    if (tag != null) {
                        tag_stack.append (tag);
                    }
                }
            } else {
                parse_tokens.append (ch);
                buf_index ++;
            }

            // Flush any remaining tokens
            flush_tokens ();
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

        private bool is_end () {
            return text_index >= text.length - 1;
        }

        /** Moves the parser to the next token in the text to parse */
        private unichar next () {
            text_index++;
            return text.get_char (text_index);
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
            string tokens = list_to_str (ref parse_tokens);
            buffer.insert (ref cursor, tokens, tokens.length);
        }

        /**
         * Consumes `list` and creates a plain string from it
         */
        private string list_to_str (ref SList<unichar> list) {
            StringBuilder acc = new StringBuilder.sized (list.length ());
            list.@foreach (c => {
                acc.append_unichar (c);
            });

            list = new SList<unichar> ();

            return acc.str;
        }

        private Gtk.TextIter iter_at_buffer_position () {
            Gtk.TextIter cursor;
            buffer.get_iter_at_offset (out cursor, buf_index);
            return cursor;
        }

        private void mark_at_buffer_position (string? name, bool left_gravity = false) {
            var iter = iter_at_buffer_position ();
            buffer.create_mark (name, iter, left_gravity);
        }
    }
}
