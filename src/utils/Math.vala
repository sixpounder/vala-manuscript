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

namespace Manuscript.Mathz {
    public int max (int val1, ...) {
        int max = val1;
        var list = va_list ();
        for (int? v = list.arg<int?> (); v != null ; v = list.arg<int?> ()) {
            max = max > v ? max :v;
        }

        return max;
    }

    public double fmax (double val1, ...) {
        var l = va_list ();
        double max = val1;
        while (true) {
            double? v = l.arg ();
            if (v == null) {
                break;
            }
            if (v > max) {
                max = v;
            }
        }

        return max;
    }
}
