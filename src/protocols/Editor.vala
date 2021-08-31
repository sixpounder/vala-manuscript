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

namespace Manuscript.Protocols {

    public class SearchResult : Object {
        public weak Protocols.ChunkEditor editor { get; set; }
        public weak Gtk.Widget? focusable_widget { get; set; }
        public Gtk.TextIter? iter;
    }

    public interface ChunkEditor : Object {
        public signal void model_change ();

        public virtual bool get_has_changes () {
            return false;
        }

        public virtual void focus_editor () {}
        public virtual void lock_editor () {}
        public virtual void unlock_editor () {}
        public virtual void scroll_to_cursor () {}
        public virtual void apply_format (string tag_name) {
            debug (@"Should apply tag $tag_name");
        }

        public virtual SearchResult? search_previous (string hint) {
            return null;
        }

        public virtual SearchResult? search_next (string hint) {
            return null;
        }
    }
}
