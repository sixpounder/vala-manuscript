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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace Manuscript.Widgets {
    public class FormatToolbar : Gtk.Box {
        public weak Models.TextBuffer buffer { get; construct; }

        public Gtk.ToggleButton format_bold { get; protected set; }
        public Gtk.ToggleButton format_italic { get; protected set; }
        public Gtk.ToggleButton format_underline { get; protected set; }

#if FEATURE_FOOTNOTES
        public Gtk.ToolButton insert_note_button { get; protected set; }
#endif

        private const int ICON_SIZE = 18;

        public FormatToolbar (Models.TextBuffer buffer) {
            Object (
                orientation: Gtk.Orientation.HORIZONTAL,
                homogeneous: false,
                hexpand: true,
                vexpand: false,
                halign: Gtk.Align.START,
                valign: Gtk.Align.CENTER,
                spacing: 10,
                height_request: 50,
                buffer: buffer
            );
        }

        construct {
            get_style_context ().add_class ("px-2");
            get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

            format_bold = new Gtk.ToggleButton ();
            format_bold.can_focus = false;
            format_bold.halign = Gtk.Align.START;
            format_bold.valign = Gtk.Align.FILL;
            format_bold.tooltip_text = _("Bold");
            format_bold.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            var bold_icon = new Gtk.Image ();
            bold_icon.gicon = new ThemedIcon ("format-text-bold-symbolic");
            bold_icon.pixel_size = ICON_SIZE;
            format_bold.image = bold_icon;
            pack_start (format_bold);

            format_italic = new Gtk.ToggleButton ();
            format_italic.can_focus = false;
            format_italic.halign = Gtk.Align.START;
            format_italic.valign = Gtk.Align.FILL;
            format_italic.tooltip_text = _("Italic");
            format_italic.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            var italic_icon = new Gtk.Image ();
            italic_icon.gicon = new ThemedIcon ("format-text-italic-symbolic");
            italic_icon.pixel_size = ICON_SIZE;
            format_italic.image = italic_icon;
            pack_start (format_italic);

            format_underline = new Gtk.ToggleButton ();
            format_underline.can_focus = false;
            format_underline.halign = Gtk.Align.START;
            format_underline.valign = Gtk.Align.FILL;
            format_underline.tooltip_text = _("Underline");
            format_underline.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            var underline_icon = new Gtk.Image ();
            underline_icon.gicon = new ThemedIcon ("format-text-underline-symbolic");
            underline_icon.pixel_size = ICON_SIZE;
            format_underline.image = underline_icon;
            pack_start (format_underline);

            var divider_1 = new Gtk.Separator (Gtk.Orientation.VERTICAL);
            pack_start (divider_1);

#if FEATURE_FOOTNOTES
            insert_note_button = new Gtk.ToolButton (new TextHighlightIndicator (), null);
            pack_start (insert_note_button);
#endif
        }
    }
}
