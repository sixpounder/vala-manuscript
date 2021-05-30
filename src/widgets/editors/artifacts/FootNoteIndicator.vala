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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Manuscript.Widgets {
    public class FootNoteIndicator : Gtk.Grid {
        public weak Models.FootNote? note { get; construct; }

        private bool _expanded;
        public bool expanded {
            get {
                return _expanded;
            }
            private set {
                if (value != _expanded) {
                    _expanded = value;
                    update_ui ();
                }
            }
        }

        private TextHighlightIndicator icon { get; private set; }

        public FootNoteIndicator (Models.FootNote note) {
            Object (
                note: note,
                expand: true,
                row_homogeneous: false,
                column_homogeneous: false,
                row_spacing: 15
            );
        }

        construct {
            icon = new TextHighlightIndicator ();
            icon.button_press_event.connect (on_activated);
            attach_next_to (icon, null, Gtk.PositionType.LEFT, 1);

            show_all ();
        }

        private bool on_activated (Gdk.EventButton event_button) {
            expanded = !_expanded;
            return true;
        }

        private void update_ui () {
            if (_expanded) {
                // Show popover
            } else {
                // Hide popover
            }
        }

        public void resize (int size) {
            icon.resize (size);
        }
    }
}
