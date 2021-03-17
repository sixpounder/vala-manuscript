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

namespace Manuscript.Widgets {
    public class DocumentSettings : Gtk.Box {

        public Manuscript.Window parent_window { get; construct; }
        public Gtk.Stack settings_views { get; private set; }

        public DocumentSettings (Manuscript.Window parent_window) {
            Object (
                parent_window: parent_window,
                orientation: Gtk.Orientation.VERTICAL,
                expand: true,
                valign: Gtk.Align.FILL,
                width_request: 600,
                height_request: 400
            );
        }

        construct {
            settings_views = new Gtk.Stack ();
            settings_views.get_style_context ().add_class ("horizontal linked stack-switcher");
            settings_views.margin_top = 20;
            settings_views.add_titled (
                new Settings.DocumentGeneralSettingsView (parent_window),
                "general",
                _("General")
            );
            settings_views.add_titled (
                new Settings.DocumentMetricsView (parent_window),
                "typography",
                _("Typography")
            );

            settings_views.add_titled (
                new Settings.CoversSettingsView (parent_window),
                "covers",
                _("Covers")
            );

            Gtk.StackSwitcher view_switchers = new Gtk.StackSwitcher ();
            view_switchers.orientation = Gtk.Orientation.HORIZONTAL;
            view_switchers.margin_start = 50;
            view_switchers.margin_end = 50;
            view_switchers.expand = false;
            view_switchers.halign = Gtk.Align.CENTER;
            view_switchers.valign = Gtk.Align.START;
            view_switchers.stack = settings_views;

            pack_start (view_switchers);
            pack_start (settings_views);
            show_all ();
        }
    }
}
