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

namespace Manuscript.Widgets {
    public class StatusBar : Gtk.ActionBar {
        protected Gtk.Label words_label;
        protected Gtk.Label reading_time_label;
        protected Gtk.Image reading_time_icon;
        protected ScrollProgress scroll_progress_indicator { get; set; }

        public weak Manuscript.Window parent_window { get; construct; }
        public weak Models.Document document {
            get {
                return parent_window.document_manager.document;
            }
        }

        public Models.DocumentChunk chunk { get; set; }

        public StatusBar (Manuscript.Window parent_window, Models.DocumentChunk chunk) {
            Object (
                parent_window: parent_window,
                chunk: chunk
            );

            assert (chunk != null);

            get_style_context ().add_class ("status-bar");

            words_label = new Gtk.Label ("0 " + _("words"));
            pack_start (words_label);

            scroll_progress_indicator = new Widgets.ScrollProgress (null);
            set_center_widget (scroll_progress_indicator);

            reading_time_label = new Gtk.Label ("");
            reading_time_label.tooltip_text = _("Estimated reading time");
            pack_end (reading_time_label);

            reading_time_icon = new Gtk.Image ();
            reading_time_icon.gicon = new ThemedIcon ("preferences-system-time-symbolic");
            reading_time_icon.pixel_size = 16;
            pack_end (reading_time_icon);

            init ();
        }

        protected string format_reading_time (double minutes) {
            return minutes <= 1
                ? "< 1 " + _("minute")
                : minutes.to_string () + " " + _("minutes");
        }

        protected string format_words_count (double words) {
            return words.to_string () + " " + _("words");
        }

        protected void init () {
            if (chunk != null) {
                words_label.label = format_words_count (chunk.words_count);
                reading_time_label.label = format_reading_time (chunk.estimate_reading_time);

                chunk.analyze.connect (() => {
                   reading_time_label.label = format_reading_time (chunk.estimate_reading_time);
                   words_label.label = format_words_count (chunk.words_count);
                });
            }
        }

        public void update_scroll_progress (double value, double min, double max) {
            scroll_progress_indicator.current_value = value;
            scroll_progress_indicator.min_value = min;
            scroll_progress_indicator.max_value = max;
        }
    }
}
