namespace Manuscript.Protocols {
    public enum ContentEvent {
        CONTENT_CHANGE,
        ATTRIBUTE_CHANGE
    }

    public class SearchResult : Object {
        public weak EditorController editor { get; set; }
        public Gtk.TextIter? iter;
    }

    public interface DocumentStats {
        public abstract uint words_count { get; }
        public abstract uint[] estimated_reading_time { get; }
    }

    public interface EditorViewController {
        public abstract unowned List<EditorController> list_editors ();
        public abstract EditorController get_editor (Models.DocumentChunk chunk);
        public abstract unowned EditorController get_current_editor ();
        public abstract void add_editor (Models.DocumentChunk chunk);
        public abstract void remove_editor (Models.DocumentChunk chunk);
        public abstract void show_editor (Models.DocumentChunk chunk);
    }

    public interface EditorController : Object {
        public abstract weak Models.DocumentChunk chunk { get; construct; }
        public abstract bool has_changes ();
        public abstract void focus_editor ();
        public abstract void content_event (ContentEvent event);
        public abstract Gtk.TextBuffer get_buffer ();
        public abstract bool scroll_to_iter (Gtk.TextIter iter, double within_margin, bool use_align, double xalign, double yalign);
        public abstract bool search_for_iter (Gtk.TextIter ? start_iter, out Gtk.TextIter ? end_iter);
        public abstract bool search_for_iter_backward (Gtk.TextIter ? start_iter, out Gtk.TextIter ? end_iter);
        //  public abstract SearchResult[] search (string word);
    }
}
