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
    public class CoverEditor : Gtk.Grid, Protocols.ChunkEditor {
        public weak Models.CoverChunk chunk { get; construct; }
        public weak Manuscript.Window parent_window { get; construct; }

        public Gtk.Frame image_frame { get; construct; }
        public Gtk.Image cover_image { get; protected set; }
        public Gtk.Button select_image_button { get; construct; }

        public CoverEditor (Manuscript.Window parent_window, Models.CoverChunk chunk) {
            Object (
                parent_window: parent_window,
                chunk: chunk,
                row_homogeneous: false,
                column_homogeneous: true,
                row_spacing: 20,
                expand: true,
                halign: Gtk.Align.CENTER,
                valign: Gtk.Align.CENTER
            );
        }

        construct {
            assert (chunk.kind == Manuscript.Models.ChunkType.COVER);

            cover_image = new Gtk.Image ();

            image_frame = new Gtk.Frame (_("Cover image"));
            image_frame.add (cover_image);

            select_image_button = new Gtk.Button.with_label (_("Select cover"));

            attach_next_to (image_frame, null, Gtk.PositionType.LEFT);
            attach_next_to (select_image_button, image_frame, Gtk.PositionType.BOTTOM);

            chunk.notify["locked"].connect (reflect_lock_status);

            update_ui ();
            reflect_lock_status ();

            show_all ();
        }

        public void update_ui () {
            if (chunk.image != null) {
                cover_image = chunk.image;
            }
        }

        public void update_model () {}

        private void reflect_lock_status () {
            if (chunk.locked) {
                lock_editor ();
            } else {
                unlock_editor ();
            }
        }

        public void lock_editor () {
            sensitive = false;
        }

        public void unlock_editor () {
            sensitive = true;
        }
    }
}
