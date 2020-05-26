namespace Manuscript.Widgets {
    public class Editor : Gtk.SourceView {
        public bool has_changes { get; private set; }
        public Gtk.SourceSearchContext search_context = null;
        protected weak Models.DocumentChunk _chunk;
        protected Gtk.CssProvider provider;
        protected Services.AppSettings settings = Services.AppSettings.get_default ();

        public Editor (Models.DocumentChunk chunk) {
            Object (
                chunk: chunk,
                has_focus: true,
                pixels_inside_wrap: 0,
                pixels_below_lines: 20,
                wrap_mode: Gtk.WrapMode.WORD,
                expand: true
            );

            try {
                init_editor ();
                search_context = new Gtk.SourceSearchContext (buffer as Gtk.SourceBuffer, null);
                settings.change.connect (on_setting_change);
                destroy.connect (on_destroy);
            } catch (Error e) {
                error ("Cannot instantiate editor view: " + e.message);
            }

        }

        public weak Models.DocumentChunk chunk {
            get {
                return _chunk;
            }
            set {
                _chunk = value;
                debug (@"Loading buffer for $(_chunk.title)");
                load_buffer (_chunk.buffer);
            }
        }

        public void scroll_down () {
            var clock = get_frame_clock ();
            var duration = 200;

            var start = vadjustment.get_value ();
            var end = vadjustment.get_upper () - vadjustment.get_page_size ();
            var start_time = clock.get_frame_time ();
            var end_time = start_time + 1000 * duration;

            add_tick_callback ( (widget, frame_clock) => {
                var now = frame_clock.get_frame_time ();
                if (now < end_time && vadjustment.get_value () != end) {
                    double t = (now - start_time) / (end_time - start_time);
                    t = ease_out_cubic (t);
                    vadjustment.set_value (start + t * (end - start) );
                    return true;
                } else {
                    vadjustment.set_value (end);
                    return false;
                }
            } );
        }

        public bool scroll_to_cursor () {
            scroll_to_mark (buffer.get_insert (), 0.0, true, 0.0, 0.5);
            return settings.zen;
        }

        protected void init_editor () throws GLib.Error {
            get_style_context ().add_provider (get_editor_style (), Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            right_margin = 100;
            left_margin = 100;
            top_margin = 50;
            bottom_margin = 50;
            wrap_mode = Gtk.WrapMode.WORD;
            indent = 20;
            input_hints = Gtk.InputHints.SPELLCHECK | Gtk.InputHints.NO_EMOJI;
        }

        protected void load_buffer (Gtk.SourceBuffer new_buffer) {
            buffer = new_buffer;
            update_settings (null);
        }

        protected void update_settings (string ? key = null) {
            if (buffer != null) {
                if (settings.zen) {
                    set_focused_paragraph ();
                    buffer.notify["cursor-position"].connect (set_focused_paragraph);
                } else {
                    Gtk.TextIter start, end;
                    Gtk.TextTag[] tags =
                        (buffer.tag_table as DocumentTagTable).for_theme (
                            settings.theme
                        );
                    buffer.get_bounds (out start, out end);
                    buffer.remove_tag (tags[1], start, end);
                    buffer.remove_tag (tags[0], start, end);
                    buffer.notify["cursor-position"].disconnect (set_focused_paragraph);
                }
            } else {
                warning ("Settings not updated, current buffer is null");
            }
        }

        protected void set_focused_paragraph () {
            Gtk.TextIter cursor_iter;
            Gtk.TextIter start, end;

            buffer.get_bounds (out start, out end);

            var cursor = this.buffer.get_insert ();
            buffer.get_iter_at_mark (out cursor_iter, cursor);

            if (cursor != null) {
                Gtk.TextIter sentence_start = cursor_iter;
                if (cursor_iter != start) {
                    sentence_start.backward_sentence_start ();
                }

                Gtk.TextIter sentence_end = cursor_iter;

                if (cursor_iter != end) {
                    sentence_end.forward_sentence_end ();
                }

                buffer.remove_tag (buffer.tag_table.lookup ("light-focused"), start, end);
                buffer.apply_tag (buffer.tag_table.lookup ("light-dimmed"), start, end);
                buffer.apply_tag (buffer.tag_table.lookup ("light-focused"), sentence_start, sentence_end);

                scroll_to_cursor ();
            }
        }

        public bool search_for_iter (Gtk.TextIter ? start_iter, out Gtk.TextIter ? end_iter) {
            end_iter = start_iter;
            bool found = search_context.forward2 (start_iter, out start_iter, out end_iter, null);
            if (found) {
                buffer.select_range (start_iter, end_iter);
                scroll_to_iter (start_iter, 0, false, 0, 0);
            }

            return found;
        }

        public bool search_for_iter_backward (Gtk.TextIter ? start_iter, out Gtk.TextIter ? end_iter) {
            end_iter = start_iter;
            bool found = search_context.backward2 (start_iter, out start_iter, out end_iter, null);
            if (found) {
                buffer.select_range (start_iter, end_iter);
                scroll_to_iter (start_iter, 0, false, 0, 0);
            }

            return found;
        }

        protected void on_setting_change (string key) {
            update_settings (key);
        }

        protected void on_document_change () {
            has_changes = true;
        }

        protected void on_document_saved (string to_path) {
            has_changes = false;
        }

        protected void on_destroy () {
            settings.change.disconnect (on_setting_change);
        }
    }
}
