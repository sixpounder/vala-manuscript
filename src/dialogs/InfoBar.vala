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
    public class MessageInfoBar : Gtk.InfoBar {
        public string message { get; set; }

        public MessageInfoBar (string message, Gtk.MessageType type) {
            Object (
                show_close_button: true,
                message_type: type,
                message: message,
                revealed: true
            );
        }

        construct {
            Gtk.Label message_label = new Gtk.Label (this.message);
            this.get_content_area ().add (message_label);
        }
    }
}
