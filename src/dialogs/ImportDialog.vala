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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Manuscript.Dialogs {
    public class ImportDialog: Object {
        private Gtk.FileChooserDialog dialog { get; set; }
        private Services.AppSettings settings;
        public weak Manuscript.Window parent_window { get; construct; }
        public weak Manuscript.Models.Document document { get; construct; }

        public ImportDialog (Manuscript.Window parent_window, Manuscript.Models.Document document) {
            Object (
                parent_window: parent_window,
                document: document
            );
        }

        construct {
            settings = Services.AppSettings.get_default ();
            dialog = new Gtk.FileChooserDialog (
                _ ("Import manuscript"),
                parent_window,
                Gtk.FileChooserAction.OPEN,
                _ ("Cancel"),
                Gtk.ResponseType.CANCEL,
                _ ("Open"),
                Gtk.ResponseType.ACCEPT
            );

            dialog.select_multiple = false;
            dialog.do_overwrite_confirmation = false;

            Gtk.FileFilter file_filter = new Gtk.FileFilter ();
            file_filter.set_filter_name (_ ("Manuscripts"));

            foreach (string ext in settings.supported_extensions) {
                file_filter.add_pattern (ext);
            }
            dialog.add_filter (file_filter);

            Gtk.FileFilter all_files = new Gtk.FileFilter ();
            all_files.set_filter_name (_ ("All files"));
            foreach (string mime in settings.supported_mime_types) {
                all_files.add_mime_type (mime);
            }
            all_files.add_pattern ("*.*");
            dialog.add_filter (all_files);
        }

        public int run () {
            var res = dialog.run ();
            dialog.destroy ();

            return res;
        }
    }
}
