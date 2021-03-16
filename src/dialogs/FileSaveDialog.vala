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
    //  public class FileSaveDialog : Gtk.FileChooserDialog {

    //      public unowned Models.Document document { get; construct; }

    //      public FileSaveDialog (Gtk.ApplicationWindow parent, Models.Document document) {
    //          Object (
    //              transient_for: parent,
    //              modal: true,
    //              do_overwrite_confirmation: true,
    //              create_folders: true,
    //              action: Gtk.FileChooserAction.SAVE,
    //              document: document
    //          );

    //      }

    //      construct {
    //          set_current_name (document.filename);
    //          add_button (_("Save document"), Gtk.ResponseType.ACCEPT);
    //          add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
    //      }
    //  }

    public Gtk.FileChooserDialog file_save_dialog (Gtk.ApplicationWindow parent, Models.Document document) {
        Gtk.FileChooserDialog dialog = new Gtk.FileChooserDialog (
            _ ("Save manuscript"),
            parent,
            Gtk.FileChooserAction.SAVE,
            _ ("Cancel"),
            Gtk.ResponseType.CANCEL,
            _ ("Save"),
            Gtk.ResponseType.ACCEPT
        );

        dialog.select_multiple = false;
        dialog.do_overwrite_confirmation = true;
        dialog.set_current_name (document.filename);

        return dialog;
    }
}
