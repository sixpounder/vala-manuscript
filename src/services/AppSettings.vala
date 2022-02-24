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

namespace Manuscript.Services {
    public class AppSettings : Object {
        public signal void change (string key);
        public string[] supported_mime_types { get; set; }
        public string[] supported_extensions { get; set; }
        public int window_width { get; set; }
        public int window_height { get; set; }
        public int window_x { get; set; }
        public int window_y { get; set; }
        public string last_opened_document { get; set; }
        public bool searchbar { get; set; }
        public bool focus_mode { get; set; }
        public bool autosave { get; set; }
        public bool use_document_typography { get; set; }
        public string theme { get; set; }
        public double text_scale_factor { get; set; }
        public bool prefer_dark_style {
            get {
                return settings.get_boolean ("prefer-dark-style");
            }
            set {
                settings.set_boolean ("prefer-dark-style", value);
                Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = value;
            }
        }

        private GLib.Settings ? settings = null;

        private static AppSettings instance;

        private AppSettings () {
            settings = new GLib.Settings (Constants.APP_ID);
            settings.bind ("mime-types", this, "supported_mime_types", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("extensions", this, "supported_extensions", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("searchbar", this, "searchbar", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("window-width", this, "window_width", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("window-height", this, "window_height", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("window-x", this, "window_x", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("window-y", this, "window_y", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("last-opened-document", this, "last_opened_document", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("focus-mode", this, "focus_mode", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("autosave", this, "autosave", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("use-document-typography", this, "use_document_typography", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("theme", this, "theme", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("text-scale-factor", this, "text_scale_factor", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("prefer-dark-style", this, "prefer_dark_style", GLib.SettingsBindFlags.DEFAULT);

            settings.changed.connect (this.on_change);
        }

        public static unowned AppSettings get_default () {
            if (instance == null) {
                instance = new AppSettings ();
            }

            return instance;
        }

        protected void on_change (string key) {
            change (key);
        }
    }
}
