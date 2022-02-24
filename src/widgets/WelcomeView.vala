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

namespace Manuscript.Widgets {
    public class WelcomeView : Gtk.Grid {
        public signal void should_open_file ();
        public signal void should_create_new_file ();

        construct {
            var welcome =
                new Granite.Widgets.Welcome (
                    _("Welcome to " + Constants.APP_NAME), _("Distraction free writing environment")
                );
            welcome.append ("document-new", _("New manuscript"), _("Create a new empty manuscript"));
            welcome.append ("document-open", _("Open"), _("Open an existing manuscript"));

            add (welcome);

            welcome.activated.connect ((index) => {
                switch (index) {
                    case 0:
                        this.should_create_new_file ();
                        break;
                    case 1:
                        this.should_open_file ();
                        break;
                }
            });
        }
    }
}
