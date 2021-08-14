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

namespace Manuscript.Models {
    public const string TAG_NAME_BOLD = "b";
    public const string TAG_NAME_ITALIC = "i";
    public const string TAG_NAME_UNDERLINE = "u";
    public const string TAG_NAME_STRIKETHROUGH = "s";

    public class XManuscriptTagTable : Gtk.TextTagTable {

        public Gtk.TextTag light_dimmed;
        public Gtk.TextTag light_focused;
        public Gtk.TextTag dark_dimmed;
        public Gtk.TextTag dark_focused;
        public Gtk.TextTag italic;
        public Gtk.TextTag bold;
        public Gtk.TextTag underline;
        public Gtk.TextTag justify_left;
        public Gtk.TextTag justify_center;
        public Gtk.TextTag justify_right;
        public Gtk.TextTag justify_fill;
        public Gtk.TextTag search_match;

        construct {
            light_dimmed = new Gtk.TextTag ("theme-light-dimmed");
            light_dimmed.foreground = "#ccc";

            light_focused = new Gtk.TextTag ("theme-light-focused");
            light_focused.foreground = "#333";

            dark_dimmed = new Gtk.TextTag ("dark-dimmed");
            dark_dimmed.foreground = "#666666";

            dark_focused = new Gtk.TextTag ("dark-focused");
            dark_focused.foreground = "#fafafa";

            italic = new Gtk.TextTag (TAG_NAME_ITALIC);
            italic.style = Pango.Style.ITALIC;

            bold = new Gtk.TextTag (TAG_NAME_BOLD);
            bold.weight = Pango.Weight.BOLD;

            underline = new Gtk.TextTag (TAG_NAME_UNDERLINE);
            underline.underline = Pango.Underline.SINGLE;

            justify_left = new Gtk.TextTag ("justify-left");
            justify_left.justification = Gtk.Justification.LEFT;

            justify_right = new Gtk.TextTag ("justify-right");
            justify_right.justification = Gtk.Justification.RIGHT;

            justify_center = new Gtk.TextTag ("justify-center");
            justify_center.justification = Gtk.Justification.CENTER;

            justify_fill = new Gtk.TextTag ("justify-fill");
            justify_fill.justification = Gtk.Justification.FILL;

            add (light_dimmed);
            add (light_focused);
            add (dark_dimmed);
            add (dark_focused);
            add (italic);
            add (bold);
            add (underline);
            add (justify_left);
            add (justify_right);
            add (justify_center);
            add (justify_fill);
        }
    }
}
