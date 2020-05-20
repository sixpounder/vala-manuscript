namespace Manuscript.Widgets {
    public class CharacterSheetEditor : Object, Protocols.EditorController {
        public weak Models.DocumentChunk chunk { get; construct; }
        public bool has_changes () {
            return false;
        }
        public void focus_editor () {}
        public void on_stats_updated (DocumentStats stats) {}
    }
}
