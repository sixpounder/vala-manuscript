namespace Manuscript.Protocols {
    public enum ContentEvent {
        CONTENT_CHANGE,
        ATTRIBUTE_CHANGE
    }

    public interface DocumentStats {
        public abstract uint words_count { get; }
        public abstract uint[] estimated_reading_time { get; }
    }

    public interface EditorViewController {
        public abstract unowned List<EditorController> list_editors ();
        public abstract EditorController get_editor (Models.DocumentChunk chunk);
        public abstract void add_editor (Models.DocumentChunk chunk);
        public abstract void remove_editor (Models.DocumentChunk chunk);
        public abstract void show_editor (Models.DocumentChunk chunk);
    }

    public interface EditorController : Object {
        public abstract weak Models.DocumentChunk chunk { get; construct; }
        public abstract bool has_changes ();
        public abstract void focus_editor ();
        public abstract void content_event (ContentEvent event);
    }
}
