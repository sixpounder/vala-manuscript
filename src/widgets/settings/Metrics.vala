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

namespace Manuscript.Widgets.Settings {
    public class DocumentMetricsView : Gtk.Grid {
        public Manuscript.Window parent_window { get; construct; }
        public Services.DocumentManager document_manager { get; private set; }
        public Gtk.SpinButton paragraph_spacing_input { get; set; }
        public Gtk.SpinButton paragraph_start_padding_input { get; set; }
        public Gtk.FontButton font_button { get; set; }

        public DocumentMetricsView (Manuscript.Window parent_window) {
            Object (
                parent_window: parent_window,
                expand: true,
                halign: Gtk.Align.CENTER,
                valign: Gtk.Align.START,
                column_spacing: 10,
                row_spacing: 10
            );
        }

        construct {
            document_manager = parent_window.document_manager;

            Gtk.Label font_label = new Gtk.Label (_("Font"));
            font_label.halign = Gtk.Align.END;
            font_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

            font_button = new Gtk.FontButton.with_font (
                document_manager.document.settings.font_family != null
                    ? document_manager.document.settings.font_family
                    : Constants.DEFAULT_FONT_FAMILY
            );
            font_button.use_font = true;
            font_button.show_size = true;
            font_button.show_style = true;
            font_button.font_set.connect (() => {
                Pango.FontDescription font_face = font_button.get_font_desc ();
                if (font_face != null) {
                    document_manager.document.settings.font_family = font_face.get_family ();
                    document_manager.document.settings.font_size = font_face.get_size_is_absolute ()
                        ? font_face.get_size ()
                        : font_face.get_size () / Pango.SCALE;
                }
                //  @"$(font_button.font_desc.get_family ()) $(font_button.font_desc.get_size () / 1000)";
            });
            attach (font_label, 0, 0, 1, 1);
            attach (font_button, 1, 0, 1, 1);

            Gtk.Label paragraph_spacing_label = new Gtk.Label (_("Paragraph spacing"));
            paragraph_spacing_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            paragraph_spacing_label.halign = Gtk.Align.END;
            paragraph_spacing_input = new Gtk.SpinButton.with_range (0, 1000, 1);
            paragraph_spacing_input.value = 10;
            paragraph_spacing_input.value_changed.connect (() => {
                if (document_manager.has_document) {
                    document_manager.document.settings.paragraph_spacing = paragraph_spacing_input.value;
                }
            });
            attach (paragraph_spacing_label, 0, 1, 1, 1);
            attach (paragraph_spacing_input, 1, 1, 1, 1);

            Gtk.Label paragraph_start_padding_label = new Gtk.Label (_("Paragraph initial padding"));
            paragraph_start_padding_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            paragraph_start_padding_label.halign = Gtk.Align.END;
            paragraph_start_padding_input = new Gtk.SpinButton.with_range (0, 1000, 1);
            paragraph_start_padding_input.value = 10;
            paragraph_start_padding_input.value_changed.connect (() => {
                if (document_manager.has_document) {
                    document_manager.document.settings.paragraph_start_padding = paragraph_start_padding_input.value;
                }
            });
            attach (paragraph_start_padding_label, 0, 2, 1, 1);
            attach (paragraph_start_padding_input, 1, 2, 1, 1);

            document_manager.load.connect (load_document_settings);

            if (document_manager.has_document) {
                load_document_settings (document_manager.document);
            }
        }

        ~DocumentMetricsView () {
            document_manager.load.disconnect (load_document_settings);
        }

        public void load_document_settings (Models.Document document) {
            Pango.FontDescription font = new Pango.FontDescription ();

            font.set_family (
                document_manager.document.settings.font_family != null
                    ? document_manager.document.settings.font_family
                    : Constants.DEFAULT_FONT_FAMILY
            );
            int64 size = document_manager.document.settings.font_size != 0
                ? document_manager.document.settings.font_size
                : Constants.DEFAULT_FONT_SIZE;
            font.set_size ((int) size * Pango.SCALE);
            font_button.set_font_desc (font);

            paragraph_spacing_input.value = document.settings.paragraph_spacing;
            paragraph_start_padding_input.value = document.settings.paragraph_start_padding;
        }
    }
}
