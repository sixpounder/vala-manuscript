namespace Manuscript.Models {
    public class Chapter : DocumentChunk {
        public Chapter () {
            Object (
                chunk_type: ChunkType.CHAPTER
            );
        }
   }
}
