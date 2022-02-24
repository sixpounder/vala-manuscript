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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Manuscript.Models.Conversion {
    public GLib.List<G> to_list<G> (Gee.ArrayList<G> gee_list) {
        var r = new GLib.List<G> ();
        var it = gee_list.iterator ();
        while (it.has_next ()) {
            it.next ();
            r.append (it.@get ());
        }

        return r;
    }

    public G[] list_to_array<G> (List<G> list) {
        var r = new G[list.length ()];
        for (uint i = 0; i < list.length (); i++) {
            r[i] = list.nth_data (i);
        }

        return r;
    }

    public Gee.ArrayList<G> to_array_list<G> (GLib.List<G> list) {
        var r = new Gee.ArrayList<G> ();
        for (uint i = 0; i < list.length (); i++) {
            r.add (list.nth_data (i));
        }

        return r;
    }
}
