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

namespace Manuscript.Services {
    public class Notification : Object {
        protected static Application application { get; set; }

        public static void init (Application app) {
            application = app;
        }

        public static void show (string title, string? body) {
#if NOTIFICATIONS
            var notification = new GLib.Notification (title);
            if (body != null) {
                notification.set_body (body);
            }
            application.send_notification (Manuscript.Constants.APP_ID, notification);
#endif
        }
    }
}
