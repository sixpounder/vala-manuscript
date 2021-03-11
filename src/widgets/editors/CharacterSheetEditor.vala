namespace Manuscript.Widgets {
    public class CharacterSheetEditor : Object, Protocols.EditorController {
        public weak Models.DocumentChunk chunk { get; construct; }

        construct {
            assert (chunk.kind == Manuscript.Models.ChunkType.CHARACTER_SHEET);
        }
    }
}
