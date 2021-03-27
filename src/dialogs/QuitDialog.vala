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
    public class QuitDialog : Granite.MessageDialog {
        public QuitDialog (Gtk.ApplicationWindow parent) {
            Object (
                buttons: Gtk.ButtonsType.NONE,
                transient_for: parent
            );
        }

        construct {
            set_modal (true);

            image_icon = new ThemedIcon ("dialog-warning");

            primary_text = _("Document has unsaved changes");

            secondary_text = _("Leaving now will result in a loss of unsaved changes. It is strongly suggested to save your changes before proceeding."); // vala-lint=line-length

            add_button (_("Keep editing"), 0);

            var close_button = add_button (_ ("Close this document"), 1);

            close_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        }
    }
}
