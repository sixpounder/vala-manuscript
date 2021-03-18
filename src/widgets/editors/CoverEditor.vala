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
    public class CoverEditor : Gtk.ScrolledWindow, Protocols.ChunkEditor {
        public weak Models.CoverChunk chunk { get; construct; }
        public weak Manuscript.Window parent_window { get; construct; }

        public Gtk.AspectFrame image_frame { get; construct; }
        public Gtk.Image cover_image { get; protected set; }
        public Gtk.Button select_image_button { get; construct; }
        public Gtk.Button random_unsplash_image_button { get; construct; }

        public CoverEditor (Manuscript.Window parent_window, Models.CoverChunk chunk) {
            Object (
                parent_window: parent_window,
                chunk: chunk,
                expand: true,
                kinetic_scrolling: true,
                overlay_scrolling: true,
                hscrollbar_policy: Gtk.PolicyType.NEVER,
                vscrollbar_policy: Gtk.PolicyType.AUTOMATIC,
                propagate_natural_width: false
            );
        }

        construct {
            assert (chunk.kind == Manuscript.Models.ChunkType.COVER);

            Gtk.Grid layout = new Gtk.Grid ();
            layout.row_homogeneous = false;
            layout.column_homogeneous = true;
            layout.row_spacing = 20;
            layout.column_spacing = 10;
            layout.expand = true;
            layout.halign = Gtk.Align.CENTER;
            layout.valign = Gtk.Align.CENTER;

            cover_image = new Gtk.Image ();
            cover_image.show ();

            image_frame = new Gtk.AspectFrame (
                "",
                0.5f,
                0.5f,
                1.0f,
                true
            );
            image_frame.label_xalign = 0.5f;
            image_frame.label_yalign = 0f;
            image_frame.get_style_context ().add_class ("p-1");
            image_frame.hexpand = true;
            image_frame.add (cover_image);
            image_frame.no_show_all = true;

            select_image_button = new Gtk.Button.with_label (_("Select cover"));
            select_image_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
            select_image_button.clicked.connect (select_cover);

            random_unsplash_image_button = new Gtk.Button.with_label (_("Random from Unsplash™"));
            random_unsplash_image_button.clicked.connect (random_cover);

            layout.attach_next_to (image_frame, null, Gtk.PositionType.LEFT, 2);
            layout.attach_next_to (random_unsplash_image_button, image_frame, Gtk.PositionType.BOTTOM, 1);
            layout.attach_next_to (select_image_button, random_unsplash_image_button, Gtk.PositionType.RIGHT, 1);

            chunk.notify["locked"].connect (reflect_lock_status);
            chunk.image_changed.connect (update_ui);

            update_ui ();
            reflect_lock_status ();

            add (layout);

            show_all ();
        }

        ~ CoverEditor () {
            chunk.notify["locked"].disconnect (reflect_lock_status);
            chunk.image_changed.disconnect (update_ui);
            select_image_button.clicked.disconnect (select_cover);
            random_unsplash_image_button.clicked.disconnect (random_cover);
        }

        public void select_cover () {
            var dialog = new Gtk.FileChooserDialog (
                _ ("Select cover image"),
                parent_window,
                Gtk.FileChooserAction.OPEN,
                _ ("Cancel"),
                Gtk.ResponseType.CANCEL,
                _ ("Select"),
                Gtk.ResponseType.ACCEPT
            );

            dialog.modal = true;
            dialog.select_multiple = false;

            Gtk.FileFilter file_filter = new Gtk.FileFilter ();
            file_filter.set_filter_name (_("Image files"));
            file_filter.add_mime_type ("image/*");

            dialog.add_filter (file_filter);

            var res = dialog.run ();

            if (res == Gtk.ResponseType.ACCEPT) {
                chunk.load_cover_from_file.begin (dialog.get_filename ());
            }

            dialog.destroy ();
        }

        public async void random_cover () {
            try {
                var input_stream = File.new_for_uri (Constants.RANDOM_IMAGE_SOURCE_URI);
                var data = yield input_stream.read_async ();
                chunk.load_cover_from_stream.begin (data, (buf) => {
                    info ("Fetched random image");
                });
            } catch (GLib.Error err) {
                error (err.message);
            }
        }

        public void update_ui () {
            if (chunk.pixel_buffer != null) {
                image_frame.label = @"$(chunk.pixel_buffer.width) x $(chunk.pixel_buffer.height)";
                cover_image.set_from_pixbuf (chunk.pixel_buffer);
                image_frame.show ();
            } else {
                image_frame.hide ();
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
