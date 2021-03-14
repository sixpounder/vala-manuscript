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
        public Gtk.TextIter? iter;
        public string? field_name { get; set; }
    }

    public interface DocumentStats {
        public abstract uint words_count { get; }
        public abstract uint[] estimated_reading_time { get; }
    }

    public interface EditorViewController {
        //  public abstract EditorController? get_editor (Models.DocumentChunk chunk);
        public abstract unowned Protocols.ChunkEditor? get_current_editor ();
        public abstract void add_editor (Models.DocumentChunk chunk);
        public abstract void remove_editor (Models.DocumentChunk chunk);
        public abstract void show_editor (Models.DocumentChunk chunk);
    }

    public interface ChunkEditor : Object {
        public virtual bool has_changes () {
            return false;
        }

        public virtual void focus_editor () {}

        public virtual void scroll_to_cursor () {}
    }
}
