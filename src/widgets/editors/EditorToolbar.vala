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

 namespace Manuscript.Widgets {
    public class EditorToolbar : Gtk.Box {
        public weak Models.TextBuffer buffer { get; construct; }

        public Gtk.ToggleButton format_bold { get; protected set; }
        public Gtk.ToggleButton format_italic { get; protected set; }
        public Gtk.ToggleButton format_underline { get; protected set; }
        public Gtk.Button quote_open { get; protected set; }
        public Gtk.Button quote_close { get; protected set; }

#if FEATURE_FOOTNOTES
        public Gtk.ToolButton insert_note_button { get; protected set; }
#endif

        private const int ICON_SIZE = 18;

        public EditorToolbar (Models.TextBuffer buffer) {
            Object (
                orientation: Gtk.Orientation.HORIZONTAL,
                homogeneous: false,
                halign: Gtk.Align.START,
                valign: Gtk.Align.CENTER,
                hexpand: true,
                vexpand: false,
                border_width: 0,
                spacing: 10,
                height_request: 50,
                margin_top: 10,
                margin_bottom: 10,
                buffer: buffer
            );
        }

        construct {
            get_style_context ().add_class ("px-2");
            get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

            format_bold = new Gtk.ToggleButton ();
            format_bold.focus_on_click = false;
            format_bold.can_focus = false;
            format_bold.halign = Gtk.Align.START;
            format_bold.valign = Gtk.Align.FILL;
            format_bold.tooltip_text = _("Bold");
            format_bold.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            var bold_icon = new Gtk.Image ();
            bold_icon.gicon = new ThemedIcon ("format-text-bold-symbolic");
            bold_icon.pixel_size = ICON_SIZE;
            format_bold.image = bold_icon;
#if GTK_4
            append (format_bold);
#else
            pack_start (format_bold);
#endif

            format_italic = new Gtk.ToggleButton ();
            format_italic.focus_on_click = false;
            format_italic.can_focus = false;
            format_italic.halign = Gtk.Align.START;
            format_italic.valign = Gtk.Align.FILL;
            format_italic.tooltip_text = _("Italic");
            format_italic.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            var italic_icon = new Gtk.Image ();
            italic_icon.gicon = new ThemedIcon ("format-text-italic-symbolic");
            italic_icon.pixel_size = ICON_SIZE;
            format_italic.image = italic_icon;
#if GTK_4
            append (format_italic);
#else
            pack_start (format_italic);
#endif

            format_underline = new Gtk.ToggleButton ();
            format_underline.focus_on_click = false;
            format_underline.can_focus = false;
            format_underline.halign = Gtk.Align.START;
            format_underline.valign = Gtk.Align.FILL;
            format_underline.tooltip_text = _("Underline");
            format_underline.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            var underline_icon = new Gtk.Image ();
            underline_icon.gicon = new ThemedIcon ("format-text-underline-symbolic");
            underline_icon.pixel_size = ICON_SIZE;
            format_underline.image = underline_icon;
#if GTK_4
            append (format_underline);
#else
            pack_start (format_underline);
#endif

            var divider_1 = new Gtk.Separator (Gtk.Orientation.VERTICAL);
#if GTK_4
            append (divider_1);
#else
            pack_start (divider_1);
#endif

#if FEATURE_FOOTNOTES
            var insert_note_image = new Gtk.Image ();
            insert_note_image.gicon = new ThemedIcon ("format-text-highlight");
            insert_note_image.pixel_size = ICON_SIZE;

            insert_note_button = new Gtk.ToolButton (insert_note_image, null);
            insert_note_button.can_focus = false;
#if GTK_4
            append (insert_note_button);
#else
            pack_start (insert_note_button);
#endif
#endif

            quote_open = new Gtk.Button.with_label (_("«"));
            quote_open.width_request = 40;
            quote_open.can_focus = false;
            quote_open.halign = Gtk.Align.START;
            quote_open.valign = Gtk.Align.FILL;
            quote_open.tooltip_text = _("Open double angle quotes");
            quote_open.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            quote_open.action_name =
                Services.ActionManager.ACTION_PREFIX + Services.ActionManager.ACTION_QUOTE_OPEN;
#if GTK_4
            append (quote_open);
#else
            pack_start (quote_open);
#endif

            quote_close = new Gtk.Button.with_label (_("»"));
            quote_close.width_request = 40;
            quote_close.can_focus = false;
            quote_close.halign = Gtk.Align.START;
            quote_close.valign = Gtk.Align.FILL;
            quote_close.tooltip_text = _("Close double angle quotes");
            quote_close.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            quote_close.action_name =
                Services.ActionManager.ACTION_PREFIX + Services.ActionManager.ACTION_QUOTE_CLOSE;
#if GTK_4
            append (quote_close);
#else
            pack_start (quote_close);
#endif

        }
    }
}
