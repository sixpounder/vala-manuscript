namespace Manuscript.Protocols {

    public class SearchResult : Object {
        public weak EditorController editor { get; set; }
        public Gtk.TextIter? iter;
        public string? field_name { get; set; }
    }

    public interface DocumentStats {
        public abstract uint words_count { get; }
        public abstract uint[] estimated_reading_time { get; }
    }

    public interface EditorViewController {
        public abstract EditorController? get_editor (Models.DocumentChunk chunk);
        public abstract unowned EditorController? get_current_editor ();
        public abstract void add_editor (Models.DocumentChunk chunk);
        public abstract void remove_editor (Models.DocumentChunk chunk);
        public abstract void show_editor (Models.DocumentChunk chunk);
    }

    public interface EditorController : Object {
        public abstract weak Models.DocumentChunk chunk { get; construct; }

        public virtual bool has_changes () {
            return false;
        }

        public virtual void focus_editor () {}

        public virtual Gtk.TextBuffer ? get_buffer () {
            return null;
        }

        public abstract bool scroll_to_iter (
            Gtk.TextIter iter, double within_margin, bool use_align, double xalign, double yalign
        );

        public virtual bool search_for_iter (Gtk.TextIter start_iter, out Gtk.TextIter ? end_iter) {
            end_iter = null;
            return false;
        }

        public virtual bool search_for_iter_backward (Gtk.TextIter start_iter, out Gtk.TextIter ? end_iter) {
            end_iter = null;
            return false;
        }

        public virtual SearchResult[] search (string word) {
            return {};
        }

        public virtual void scroll_to_search_result (SearchResult result) {}
    }
}
