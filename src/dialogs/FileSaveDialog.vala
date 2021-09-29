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

namespace Manuscript.Dialogs {
    public Gtk.FileChooserDialog file_save_dialog (Gtk.ApplicationWindow parent, Models.Document document) {
        Gtk.FileChooserDialog dialog = new Gtk.FileChooserDialog (
            Services.I18n.SAVE_MANUSCRIPT,
            parent,
            Gtk.FileChooserAction.SAVE,
            Services.I18n.CANCEL,
            Gtk.ResponseType.CANCEL,
            Services.I18n.SAVE,
            Gtk.ResponseType.ACCEPT
        );

        dialog.select_multiple = false;
        dialog.do_overwrite_confirmation = true;
        dialog.set_current_name (document.title + Constants.DEFAULT_FILE_EXT);

        return dialog;
    }
}
