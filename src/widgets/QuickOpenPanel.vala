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
    public class QuickOpenPanel: Gtk.Frame {
        public virtual signal void action (Manuscript.Models.DocumentChunk? chunk) {
            if (chunk != null) {
                document_manager.open_chunk (chunk);
            }
            hide ();
        }

        public Manuscript.Services.DocumentManager document_manager { get; construct; }
        protected uint search_timer_id = 0;
        protected Gtk.Entry query_input;
        protected Gtk.ListBox results_grid;
        protected int selected_index = 0;

        public Manuscript.Widgets.QuickOpenEntry? selected {
            get {
                return results_grid.get_row_at_index (selected_index) as Manuscript.Widgets.QuickOpenEntry;
            }
        }

        public QuickOpenPanel (Manuscript.Services.DocumentManager document_manager) {
            Object (
                document_manager: document_manager,
                label: _("Quick open"),
                width_request: 550,
                expand: false,
                halign: Gtk.Align.CENTER,
                valign: Gtk.Align.START,
                shadow_type: Gtk.ShadowType.ETCHED_OUT
            );
        }

        construct {
            var style_context = get_style_context ();
            style_context.add_class ("quick-open-panel");

            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            box.orientation = Gtk.Orientation.VERTICAL;
            box.homogeneous = false;
            box.halign = Gtk.Align.FILL;
            box.valign = Gtk.Align.START;
            box.expand = true;


            query_input = new Gtk.Entry ();
            query_input.valign = Gtk.Align.START;
            query_input.placeholder_text = _("Type to search");
            query_input.get_style_context ().add_class ("quick-open-query-entry");


            results_grid = new Gtk.ListBox ();
            results_grid.margin_top = 10;
            results_grid.selection_mode = Gtk.SelectionMode.SINGLE;

#if GTK_4
            box.append (query_input);
            box.append (results_grid);
#else
            box.pack_start (query_input);
            box.pack_start (results_grid);
#endif

            connect_events ();

            add (box);
            show_all ();
        }

        protected void connect_events () {
            show.connect (on_show);
            key_press_event.connect (on_key_pressed);
            query_input.key_press_event.connect (on_key_pressed);
            query_input.changed.connect (on_query_change);
        }

        protected bool on_key_pressed (Gdk.EventKey event) {
            if (event.keyval == Gdk.Key.Escape) {
                action (null);
                return true;
            } else if (event.keyval == Gdk.Key.Return) {
                if (selected != null) {
                    action (selected.chunk);
                } else {
                    action (null);
                }
                return true;
            } else if (event.keyval == Gdk.Key.Down) {
                select_next_result ();
                return true;
            } else if (event.keyval == Gdk.Key.Up) {
                select_previous_result ();
                return true;
            } else {
                return false;
            }
        }

        protected void on_query_change () {
            if (search_timer_id != 0) {
                GLib.Source.remove (search_timer_id);
            }
            search_timer_id = Timeout.add (Manuscript.Constants.QUICK_SEARCH_DEBOUNCE_TIME, () => {
                search_timer_id = 0;
                search ();
                return false;
            });
        }

        protected void on_show () {
            query_input.grab_focus ();
        }

        protected void search () {
            string word = query_input.text;
            if (word.length != 0) {
                word = word.down ();
                var chunks = document_manager.document.chunks;
                if (chunks != null) {
                    debug (@"Searching for $(word)");
                    var results_buffer = chunks.filter ((item) => {
                        return item.title.down ().contains (word);
                    });
                    build_results_interface_from_iterator (results_buffer);
                }
            } else {
                reset_results_interface ();
            }
        }

        protected void reset_results_interface () {
            results_grid.@foreach ((child) => {
                results_grid.remove (child);
            });

            debug ("Quick open list cleared");
        }

        protected void build_results_interface_from_iterator (
            owned Gee.Iterator<Manuscript.Models.DocumentChunk> iter
        ) {
            reset_results_interface ();
            uint i = 0;
            while (iter.has_next ()) {
                iter.next ();
                var item = iter.@get ();
                var widget = new Manuscript.Widgets.QuickOpenEntry (item, query_input.text);
                results_grid.add (widget);
                i++;
            }

            if (i > 0) {
                results_grid.show ();
            } else {
                results_grid.hide ();
            }

            selected_index = 0;
            results_grid.select_row (
                results_grid.get_row_at_index (selected_index)
            );
            results_grid.show_all ();

            debug (@"$(i) results shown");
        }

        public void select_next_result () {
            if (selected_index < results_grid.get_children ().length () - 1) {
                selected_index ++;
            }
            results_grid.select_row (
                results_grid.get_row_at_index (selected_index)
            );
        }

        public void select_previous_result () {
            if (selected_index != 0) {
                selected_index --;
            }
            results_grid.select_row (
                results_grid.get_row_at_index (selected_index)
            );
        }
    }
}
