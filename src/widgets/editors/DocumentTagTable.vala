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

namespace Manuscript {
    public class DocumentTagTable : Gtk.TextTagTable {

        public Gtk.TextTag light_dimmed;
        public Gtk.TextTag light_focused;
        public Gtk.TextTag dark_dimmed;
        public Gtk.TextTag dark_focused;

        construct {
            light_dimmed = new Gtk.TextTag ("light-dimmed");
            light_dimmed.foreground = "#ccc";

            light_focused = new Gtk.TextTag ("light-focused");
            light_focused.foreground = "#333";

            dark_dimmed = new Gtk.TextTag ("dark-dimmed");
            dark_dimmed.foreground = "#666666";

            dark_focused = new Gtk.TextTag ("dark-focused");
            dark_focused.foreground = "#fafafa";

            add (light_dimmed);
            add (light_focused);
            add (dark_dimmed);
            add (dark_focused);
        }

        public Gtk.TextTag[] for_theme (string? theme) {
            switch (theme) {
                case "light":
                default:
                    return { light_dimmed, light_focused };
                case "dark":
                    return { dark_dimmed, dark_focused };
            }
        }
    }
}
