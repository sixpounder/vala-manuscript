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
namespace Manuscript.Dialogs {
    public class HintsDialog : Gtk.Dialog {
        private Gtk.Grid layout;

        public HintsDialog (Gtk.Window transient_for) {
            Object (
                title: _("Hints & shortcuts"),
                transient_for: transient_for,
                modal: false,
                width_request: 400,
                height_request: 400
            );
        }

        construct {
            var content = get_content_area ();
            content.margin = 10;
            content.expand = true;
            content.valign = Gtk.Align.FILL;
            content.halign = Gtk.Align.FILL;
            content.orientation = Gtk.Orientation.VERTICAL;

            layout = new Gtk.Grid ();
            layout.valign = Gtk.Align.START;
            layout.expand = true;

            var editor_section_layout = create_section_layout (_("Editor"));
            add_item_to_section (_("Find"), Services.ActionManager.ACTION_FIND, editor_section_layout);
            add_item_to_section (_("Font zoom in"), Services.ActionManager.ACTION_ZOOM_IN_FONT, editor_section_layout);
            add_item_to_section (_("Font zoom out"), Services.ActionManager.ACTION_ZOOM_OUT_FONT, editor_section_layout);
            add_item_to_section (_("Insert open quote"), Services.ActionManager.ACTION_QUOTE_OPEN, editor_section_layout);
            add_item_to_section (_("Insert close quote"), Services.ActionManager.ACTION_QUOTE_CLOSE, editor_section_layout);
            add_item_to_section (_("Text bold"), Services.ActionManager.ACTION_FORMAT_BOLD, editor_section_layout);
            add_item_to_section (_("Text italic"), Services.ActionManager.ACTION_FORMAT_ITALIC, editor_section_layout);
            add_item_to_section (_("Text underline"), Services.ActionManager.ACTION_FORMAT_UNDERLINE, editor_section_layout);
            
            layout.attach_next_to (editor_section_layout, null, Gtk.PositionType.BOTTOM, 1, 1);

            var document_section_layout = create_section_layout (_("Document"));
            add_item_to_section (_("Add chapter"), Services.ActionManager.ACTION_ADD_CHAPTER, document_section_layout);
            add_item_to_section (_("Add character sheet"), Services.ActionManager.ACTION_ADD_CHARACTER_SHEET, document_section_layout);
            add_item_to_section (_("Add note"), Services.ActionManager.ACTION_ADD_NOTE, document_section_layout);
            add_item_to_section (_("Document settings"), Services.ActionManager.ACTION_DOCUMENT_SETTINGS, document_section_layout);
            add_item_to_section (_("Export"), Services.ActionManager.ACTION_EXPORT, document_section_layout);
            add_item_to_section (_("Jump to"), Services.ActionManager.ACTION_JUMP_TO, document_section_layout);
            add_item_to_section (_("Toggle focus mode"), Services.ActionManager.ACTION_FOCUS_MODE, document_section_layout);
            
            layout.attach_next_to (document_section_layout, editor_section_layout, Gtk.PositionType.RIGHT, 1, 1);

            // Add layout to the content view
            content.pack_start (layout, true, true);

            // Add actions
            add_button (_("Close"), Gtk.ResponseType.CLOSE);

            // Show everything
            show_all ();
        }

        private Gtk.Box create_section_layout (string title) {
            var section_layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
            section_layout.hexpand = true;
            section_layout.valign = Gtk.Align.START;

            var section_label = new Gtk.Label (title);
            section_label.get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
            section_layout.pack_start (section_label, true, true);

            return section_layout;
        }

        private void add_item_to_section (string label, string action_name, Gtk.Box section) {
            var item = new Granite.AccelLabel.from_action_name (
                label,
                @"$(Services.ActionManager.ACTION_PREFIX)$(action_name)"
            );
            item.halign = Gtk.Align.CENTER;
            section.pack_start (item, true, true);
        }
    }
}
