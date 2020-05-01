namespace Manuscript.Protocols {
    public interface EditorViewController {
        public abstract unowned List<EditorController> list_editors ();
        public abstract EditorController get_editor (Models.DocumentChunk chunk);
        public abstract void add_editor (Models.DocumentChunk chunk);
        public abstract void remove_editor (Models.DocumentChunk chunk);
        public abstract void show_editor (Models.DocumentChunk chunk);
    }

    public interface EditorController {
        public abstract bool has_changes ();
        public abstract void focus_editor ();
    }
}
