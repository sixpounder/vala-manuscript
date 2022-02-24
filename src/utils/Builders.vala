/*
 * Copyright 2022 Andrea Coronese <sixpounder@protonmail.com>
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

namespace Manuscript.Utils.Builders {
    public Gtk.RadioButton build_card_radio (
        string label,
        string icon_name,
        int? icon_size = 64,
        Gtk.RadioButton? group = null
    ) {
        var pdf_icon = new Gtk.Image ();
        pdf_icon.gicon = new ThemedIcon (icon_name);
        pdf_icon.pixel_size = icon_size;

        //  var card = new Gtk.Grid () {
        //      row_spacing = 6,
        //      margin_start = 12
        //  };
        //  card.get_style_context ().add_class (Granite.STYLE_CLASS_CARD);
        //  card.get_style_context ().add_class (Granite.STYLE_CLASS_ROUNDED);

        //  card.add (pdf_icon);
        var card = pdf_icon;

        var radio_grid = new Gtk.Grid () {
            row_spacing = 6
        };

        radio_grid.attach (card, 0, 0);
        radio_grid.attach (new Gtk.Label (label), 0, 1);

        Gtk.RadioButton radio;

        if (group != null) {
            radio = new Gtk.RadioButton.from_widget (group) {
                halign = Gtk.Align.START
            };
        } else {
            radio = new Gtk.RadioButton (null) {
                halign = Gtk.Align.START
            };
        }

        radio.get_style_context ().add_class ("image-button");
        radio.add (radio_grid);

        return radio;
    }
}
