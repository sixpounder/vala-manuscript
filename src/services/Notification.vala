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

        public static void show (
            GLib.NotificationPriority? priority,
            string title,
            string? body,
            Variant? target,
            ...
        ) {
#if NOTIFICATIONS
            var notification = new GLib.Notification (title);
            notification.set_priority (priority);

            if (body != null) {
                notification.set_body (body);
            }

            var actions = va_list ();

            while (true) {
                string? action_label = actions.arg ();
                if (action_label == null) {
                    break;
                } else {
                    string action_name = actions.arg ();
                    notification.add_button_with_target_value (action_label, action_name, target);
                }
            }

            application.send_notification (Manuscript.Constants.APP_ID, notification);
#endif
        }
    }
}
