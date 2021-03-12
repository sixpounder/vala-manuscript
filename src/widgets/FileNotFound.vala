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
    public class FileNotFound : Granite.Widgets.AlertView {
        public string expected_path { get; protected set; }
        public FileNotFound (string expected_path) {
            base (
                _("File does not exist"),
                _("This file may have been deleted or moved.") + "\n" + @"<i>$expected_path</i> " + _("not found"),
                "dialog-warning"
            );

            this.expected_path = expected_path;
        }

        construct {
            action_activated.connect (() => {
                hide_action ();
            });
        }
    }
}
