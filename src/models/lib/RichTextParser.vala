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

    public class RichTextParser : Object {
        public virtual signal void parse_end (ulong millis) {
            debug ("Parsing done in %s milliseconds", millis.to_string ());
        }
        private Timer bench_timer;
        private StringBuilder parse_tokens;
        private SList<Gtk.TextTag> tag_stack;
        private TextBuffer buffer;
        private string? text;
        private int text_index;
        private int buf_index;

        public RichTextParser (TextBuffer buffer) {
            this.buffer = buffer;
        }

        construct {
            this.bench_timer = new Timer ();
            this.text_index = 0;
            this.buf_index = 0;
            this.parse_tokens = new StringBuilder.sized (100);
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

            this.bench_timer.stop ();
            ulong micros;
            this.bench_timer.elapsed (out micros);
            this.parse_end (micros / 10);
        }

        private void token (unichar ch) {
            if (
                ch == OPEN_TAG_TOKEN &&
                peek_behind () != null &&
                peek_behind () != TAG_ESCAPE_TOKEN
            ) {
                flush_tokens ();
                bool is_tag_end = peek () == '/';
                if (is_tag_end) {
                    // This is a </tag>
                    tag_end ();
                } else {
                    // This is a <tag>
                    tag_start ();
                }
            } else {
                parse_tokens.append_c ((char) ch);
            }
        }

        private void tag_start () {
            var peek_tokens = forward_until (CLOSE_TAG_TOKEN);
            var tag = buffer.tag_table.lookup (peek_tokens);
            if (tag != null) {
                tag_stack.append (tag);
            }
        }

        private void tag_end () {
            forward_until (CLOSE_TAG_TOKEN);
            Gtk.TextTag tag = tag_stack.nth_data (tag_stack.length () - 1);
            tag_stack.remove (tag);
        }

        private uint depth {
            get {
                return tag_stack.length ();
            }
        }

        /** Peeks at the next token, without advancing any counter */
        private unichar? peek () {
            if (text_index <= text.length - 1) {
                return text[text_index]; // text_index always points the the NEXT char, so no need to decrement
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
            return text_index > text.length - 1;
        }

        /** Moves the parser to the next token in the text to parse */
        private unichar next () {
            //  text_index ++;
            unichar c;
            text.get_next_char (ref text_index, out c);
            return c;
        }

        private string forward_until (unichar stop_mark) {
            var peek_tokens = new StringBuilder ();
            unichar peek_char = next ();
            while (peek_char != CLOSE_TAG_TOKEN) {
                peek_tokens.insert_unichar (peek_tokens.len, peek_char);
                peek_char = next ();
            }

            return peek_tokens.str;
        }

        /** Flushes parsed tokens to the TextBuffer */
        private void flush_tokens () {
            string tokens = parse_tokens.str;
            int start_offset = buf_index;
            int end_offset = buf_index + tokens.length;

            Gtk.TextIter cursor;
            buffer.get_end_iter (out cursor);

            buffer.insert (ref cursor, tokens, tokens.length);
            buf_index += tokens.length;

            Gtk.TextIter tag_apply_start, tag_apply_end;
            buffer.get_iter_at_offset (out tag_apply_start, start_offset);
            buffer.get_iter_at_offset (out tag_apply_end, end_offset);

            tag_stack.@foreach (tag => {
                buffer.apply_tag (tag, tag_apply_start, tag_apply_end);
            });

            parse_tokens.erase ();
        }
    }
}
