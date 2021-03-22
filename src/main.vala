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
    public class Application : Gtk.Application {
        protected Services.AppSettings settings { get; set; }

        public static bool ensure_directory_exists (File dir) {

            if (!dir.query_exists ())
                try {
                    dir.make_directory_with_parents ();
                    return true;
                } catch {
                    error ("Could not access or create the directory '%s'.", dir.get_path ());
                }

            return false;
        }

        construct {
            application_id = Constants.APP_ID;
            flags |= ApplicationFlags.HANDLES_OPEN;
            var cache_path = Path.build_path (
                Path.DIR_SEPARATOR_S, Environment.get_user_cache_dir (), Constants.APP_ID
            );
            debug (
                @"Cache folder: $(cache_path)"
            );
            Manuscript.Services.Notification.init (this);
            Application.ensure_directory_exists (
                File.new_for_path (cache_path)
            );

            settings = Services.AppSettings.get_default ();
        }

        protected override void activate () {
            init ();
        }

        protected override void open (File[] files, string hint) {
            init (files, hint);
        }

        protected void init (File[] ? files = null, string ? hint = "") {
            weak Gtk.IconTheme default_theme = Gtk.IconTheme.get_default ();
            default_theme.add_resource_path ("/com/github/sixpounder/manuscript/icons");

            settings.prefer_dark_style = Gtk.Settings.get_default ().gtk_application_prefer_dark_theme;

            Manuscript.Window main_window;

            if (files != null) {
                if (files.length != 0) {
                    foreach (File f in files) {
                        main_window = this.new_window (f.get_path ());
                    }
                } else {
                    if (settings.last_opened_document != "") {
                        main_window = this.new_window (settings.last_opened_document);
                    } else {
                        main_window = this.new_window ();
                    }
                }
            } else {
                if (settings.last_opened_document != "") {
                    main_window = this.new_window (settings.last_opened_document);
                } else {
                    main_window = this.new_window ();
                }
            }

            Globals.application = this;
        }

        public Manuscript.Window new_window (string ? document_path = null) {
            Manuscript.Window window;

            if (document_path != null && document_path != "") {
                debug ("Opening with document - " + document_path);
                window = new Manuscript.Window.with_document (this, document_path);
            } else {
                debug ("Opening with welcome view");
                window = new Manuscript.Window.with_document (this);
            }

            window.title = Constants.APP_NAME;

            window.show_all ();

            return window;
        }

        public static int main (string[] args) {
            var app = new Manuscript.Application ();
            Environment.set_application_name (Constants.APP_NAME);
            Environment.set_prgname (Constants.APP_NAME);

            return app.run (args);
        }
    }
}
