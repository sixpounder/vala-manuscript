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
    public class SidebarRow: Gtk.ListBoxRow {
        public string label { get; set; }
        public Gee.List<Gtk.ListBoxRow> children { get; set; }

        public SidebarRow (string label, Gee.List<Gtk.ListBoxRow>? children) {
            Object (
                label: label,
                children: children,
                selectable: true,
                activatable: true
            );
        }

        construct {
            var label = new Gtk.Label (label);
            add (label);
        }
    }
}
