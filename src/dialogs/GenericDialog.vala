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

namespace Manuscript.Dialogs {
    public class GenericDialog : Gtk.Dialog {
        public Gtk.Widget content_view { get; construct; }
        public Manuscript.Window parent_window { get; construct; }

        public GenericDialog (Manuscript.Window parent_window, Gtk.Widget content_view) {
            Object (
                parent_window: parent_window,
                content_view: content_view,
                modal: false,
                transient_for: parent_window
            );
        }

        construct {
#if GTK_4
            get_content_area ().append (content_view);
#else
            get_content_area ().pack_start (content_view);
#endif
        }
    }
}
