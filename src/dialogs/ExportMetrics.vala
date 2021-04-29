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

namespace Manuscript.Dialogs {
    public class ExportDialogMetrics : Gtk.Grid {
        public signal void changed ();
        public Models.Document document { get; construct; }
        private Gtk.SpinButton line_spacing_input { get; set; }
        private Gtk.SpinButton paragraph_spacing_input { get; set; }
        private Gtk.SpinButton paragraph_start_padding_input { get; set; }
        private Gtk.FontButton font_button { get; set; }

        public double paragraph_spacing {
            get {
                return paragraph_spacing_input.value;
            }
        }

        public double paragraph_start_padding {
            get {
                return paragraph_start_padding_input.value;
            }
        }

        public double line_spacing {
            get {
                return line_spacing_input.value;
            }
        }

        public ExportDialogMetrics (Models.Document document) {
            Object (
                document: document,
                expand: true,
                halign: Gtk.Align.CENTER,
                valign: Gtk.Align.START,
                column_spacing: 10,
                row_spacing: 10
            );
        }

        construct {
            Gtk.Label font_label = new Gtk.Label (_("Font"));
            font_label.halign = Gtk.Align.END;
            font_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

            font_button = new Gtk.FontButton.with_font (
                document.settings.font_family != null
                    ? document.settings.font_family
                    : Constants.DEFAULT_FONT_FAMILY
            );
            font_button.use_font = true;
            font_button.show_size = true;
            font_button.show_style = true;
            attach (font_label, 0, 0, 1, 1);
            attach (font_button, 1, 0, 1, 1);

            Gtk.Label line_spacing_label = new Gtk.Label (_("Line spacing"));
            line_spacing_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            line_spacing_label.halign = Gtk.Align.END;
            line_spacing_input = new Gtk.SpinButton.with_range (0, 1000, 1);
            line_spacing_input.value = document.settings.line_spacing;
            line_spacing_input.value_changed.connect (() => {
                changed ();
            });
            attach (line_spacing_label, 0, 1, 1, 1);
            attach (line_spacing_input, 1, 1, 1, 1);

            Gtk.Label paragraph_spacing_label = new Gtk.Label (_("Paragraph spacing"));
            paragraph_spacing_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            paragraph_spacing_label.halign = Gtk.Align.END;
            paragraph_spacing_input = new Gtk.SpinButton.with_range (0, 1000, 1);
            paragraph_spacing_input.value = document.settings.paragraph_spacing;
            paragraph_spacing_input.value_changed.connect (() => {
                changed ();
            });
            attach (paragraph_spacing_label, 0, 2, 1, 1);
            attach (paragraph_spacing_input, 1, 2, 1, 1);

            Gtk.Label paragraph_start_padding_label = new Gtk.Label (_("Paragraph initial padding"));
            paragraph_start_padding_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            paragraph_start_padding_label.halign = Gtk.Align.END;
            paragraph_start_padding_input = new Gtk.SpinButton.with_range (0, 1000, 1);
            paragraph_start_padding_input.value = document.settings.paragraph_start_padding;
            paragraph_start_padding_input.value_changed.connect (() => {
                changed ();
            });
            attach (paragraph_start_padding_label, 0, 3, 1, 1);
            attach (paragraph_start_padding_input, 1, 3, 1, 1);
        }
    }
}
